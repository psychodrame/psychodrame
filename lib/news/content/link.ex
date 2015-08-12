defmodule News.Content.Link do
  @moduledoc """
  Validates and extracts link information:
  * validate it is not a dead link
  * stores content-type
  * tbd
  """

  # TODO: Do a HEAD before the get
  # TODO: Limit request size / request time
  # TODO: Make it run in a separate process
  # TODO: Cache results for later user (if used without a model, e.g. live validation)

  @allowed_schemes ~w(http https)

  def allowed_schemes, do: @allowed_schemes

  @spec validate_link_syntax(String.t) :: {:ok, String.t} | {:error, String.t}
  def validate_link_syntax(link) when is_binary(link), do: validate_link_syntax(link, URI.parse(link))
  def validate_link_syntax(_), do: {:error, "is required"}
  defp validate_link_syntax(link, %{scheme: s, host: h}) when s in @allowed_schemes and not is_nil(h), do: {:ok, link}
  defp validate_link_syntax(_, nil), do: {:error, "is required"}
  defp validate_link_syntax(_, %{scheme: s}) when not s in @allowed_schemes, do: {:error, "scheme #{s} not allowed"}
  defp validate_link_syntax(_, _), do: {:error, "is invalid"}

  defmodule Pipeline do
    @behaviour News.ContentPipeline.Behaviour
    import Ecto.Changeset
    alias News.Content.Link
    require Logger

    def changeset(changeset, context) do
      case Link.validate_link_syntax(context.value) do
        {:ok, _} -> validate_fetch(changeset, context)
        {:error, err} -> add_error(changeset, context.field, err)
      end
    end

    def validate_fetch(changeset, context) do
      meta = Link.FetchAndExtract.fetch_and_extract(get_field(changeset, context.field))
      if meta.valid do
        preview_url = if context.value != meta.url, do: meta.url, else: nil
        attrs = get_field(changeset, :attrs)
          |> Map.put("http_status", meta.status)
          |> Map.put("domain", meta.domain)
          |> Map.put("sha", meta.sha)
          |> Map.put("content_type", meta.content_type)
          |> Map.put("type", meta.type)
          |> Map.put("thumbnail_url", meta.thumbnail_url)
          |> Map.put("preview_url", preview_url)
          |> Map.put("preview_html", meta.preview)
        News.Util.TempFile.release
        put_change(changeset, :attrs, attrs)
      else
        case meta.error do
          {:status, s} -> add_error(changeset, context.field, "link crawl returned status #{s}")
          {:fetch_error, err} -> add_error(changeset, context.field, "link crawl failed: #{inspect err}")
        end
      end
    end

    def after_save(changeset, _), do: changeset

    def finalize(model, context) do
      model
    end
  end

  defmodule FetchAndExtract do
    require Logger
    defstruct valid: false, url: nil, thumbnail_url: nil, error: nil, status: nil, domain: nil, sha: nil, file: nil, content_type: nil, type: nil, preview: nil, body: nil
    @doc "returns {changeset, temp_file_reference}"
    def fetch_and_extract(uri) do
      filtered_uri = News.Util.URIFilter.transform(URI.parse(uri))
      str_uri = News.Util.URIFilter.uri_to_string(filtered_uri)
      headers = [{"user-agent", News.user_agent(:check)}]
      options = [:insecure, {:follow_redirect, true}]
      request_result(filtered_uri, :hackney.request(:get, str_uri, headers, "", options))
        |> process_result(filtered_uri)
    end

    @ok_status [200]

    defp request_result(uri, {:ok, status, headers, client}) when status in @ok_status do
      headers = Enum.into(headers, Map.new)
      {:ok, body} = :hackney.body(client)
      uri = URI.parse uri
      sha = News.HTTP.body_sha(body)
      content_type = headers["Content-Type"]
      type = News.Util.ContentType.get_type(content_type, body)
      # TODO Check News.Util.DeadSHA

      temp_file = News.Util.TempFile.write(sha, body)
      %__MODULE__{valid: true, url: News.Util.URIFilter.uri_to_string(uri),
        status: status, domain: uri.host, sha: sha, file: temp_file, type: type,
        content_type: content_type, body: body}
    end

      defp request_result(uri, {:ok, status, headers, _}), do: %__MODULE__{valid: false, error: {:status,status}, status: status}
      defp request_result(uri, {:error, reason}), do: %__MODULE__{valid: false, error: {:fetch_error,reason}}

      # YouTube Embed
      defp process_result(struct, %URI{host: "youtube.com", path: "/watch", query: query}) do
        qs = URI.decode_query(query)
        if id = qs["v"] do
          html = embed_iframe("youtube", "//www.youtube.com/embed/#{id}")
          thumb = "https://img.youtube.com/vi/#{id}/default.jpg"
          %__MODULE__{struct | type: "video", preview: html, thumbnail_url: thumb}
        else struct end
      end

      # Vimeo Embed
      defp process_result(struct, uri=%URI{host: "vimeo.com"}) do
        case Regex.run(~r/\/(\d+)/, uri.path) do
          [_, id] ->
            html = embed_iframe("vimeo", "https://player.vimeo.com/video/#{id}?byline=0&portrait=0")

            # API Call because thumbnail
            api = News.HTTP.json_query("https://vimeo.com/api/v2/video/#{id}.json")
            thumb = if api.ok do
              body = List.first(api.body)
              body["thumbnail_small"]
            else nil end

            %__MODULE__{struct | type: "video", preview: html, thumbnail_url: thumb}
          _ -> struct
        end
      end

      # dailymotion Embed
      defp process_result(struct, uri=%URI{host: "dailymotion.com"}) do
        case Regex.run(~r/\/video\/([a-z0-9]+)_.*/, uri.path) do
          [_, id] ->
            html = embed_iframe("dailymotion", "//www.dailymotion.com/embed/video/#{id}")
            thumb = "http://www.dailymotion.com/thumbnail/video/#{id}"
            %__MODULE__{struct | type: "video", preview: html, thumbnail_url: thumb}
          _ -> struct
        end
      end

      @oembed_discovery_tags [
        "link[type=application/json+oembed]",
        "link[type=text/json+oembed]",
        #"link[type=application/xml+oembed]",
        #"link[type=text/xml+oembed]",
      ]

      defp process_result(struct, uri) do
        # Try OEmbed
        # TODO Support XML OEmbed!
        oembed = Enum.flat_map(@oembed_discovery_tags, fn(tag) ->
          Floki.find(struct.body, tag)
        end)
        unless Enum.empty?(oembed) do
          oembed(struct, oembed)
        else struct end
      end

    defp embed_iframe(class_prefix, src) do
      fullscreen = "webkitallowfullscreen mozallowfullscreen allowfullscreen"
      "<iframe class=\"embed-preview embed-#{class_prefix}\" src=\"#{src}\" \"#{fullscreen}\"></iframe>"
    end

    @allowed_embeds %{
      "api.imgur.com" => "image",
      "www.flickr.com" => "image",
      "www.collegehumor.com" => "video",
      "www.polleverywhere.com" => "link",
      "api.embed.ly" => "link",
      "api.portfolium.com" => "link",
      "www.ifixit.com" => "link",
      "backend.deviantart.com" => "image",
      "www.slideshare.net" => "link",
      "public-api.wordpress.com" => "link",
      "www.scribd.com" => "link",
      "www.nfb.ca" => "link",
      "www.rdio.com" => "audio",
      "www.mixcloud.com" => "audio",
      "api.clyp.it" => "audio",
      "www.screenr.com" => "video",
      "www.funnyordie.com" => "video",
      "polldaddy.com" => "link",
      "ted.com" => "video",
      "www.videojug.com" => "video",
      "videos.sapo.pt" => "video",
      "official.fm" => "audio",
      "huffduffer.com" => "audio",
      "shoudio.com" => "audio",
      "soundcloud.com" => "audio",
    }
    # TODO Support XML OEmbed
    defp oembed(struct, discovery) do
      case discovery do
        [{"link", link, _}] ->
          link = Enum.into(link, %{})
          uri = URI.parse(link["href"])
          #if Enum.member?(@allowed_embeds, uri.host) do
            http = News.HTTP.json_query(link["href"])
            type = @allowed_embeds[uri.host] || struct.type
            struct = %__MODULE__{struct | type: type}
            case http.body["type"] do
              "rich" ->
                # TODO: If we have to whitelist rich embeds, it's here.
                %__MODULE__{struct | preview: http.body["html"], thumbnail_url: http.body["thumbnail_url"]}
              "photo" ->
                %__MODULE__{struct | type: "image", url: http.body["url"], thumbnail_url: http.body["thumbnail_url"]}
              _ ->
                Logger.warn "Missed OEmbed type: #{inspect http.body}"
                struct
              end
          #else
          #  IO.inspect "OEmbed! #{inspect uri.host} not in #{inspect @allowed_embeds}"
          #  struct
          #end
        _ -> struct
      end
    end

  end
end
