defmodule News.Link do
  @moduledoc "Link crawling / data extraction tool"

  alias __MODULE__
  alias News.HTTP
  alias News.RedisCache
  alias News.Util.URIFilter
  alias News.Util.ContentType
  alias News.Util.TempFile
  import News, only: [user_agent: 1]
  require Logger

  defstruct valid: false, error: nil, status: nil,
            url: nil, thumbnail_url: nil, domain: nil,
            preview: nil, sha: nil, body: nil, file: nil,
            type: nil, content_type: nil

  @doc "Fetch and extracts `uri`"
  @spec process(String.t) :: %Link{}
  def process(uri) do
    filtered_uri = URIFilter.transform(URI.parse(uri))
    str_uri = URIFilter.uri_to_string(filtered_uri)
    RedisCache.cached(str_uri, fn() ->
      headers = [{"user-agent", user_agent(:check)}]
      options = [:insecure, {:follow_redirect, true}]
      request_result(filtered_uri, :hackney.request(:get, str_uri, headers, "", options))
        |> process_result(filtered_uri)
    end)
  end

  @ok_status [200]

  defp request_result(string_uri, {:ok, status, headers, client}) when status in @ok_status do
    headers = Enum.into(headers, Map.new)
    {:ok, body} = :hackney.body(client)
    uri = URI.parse string_uri
    sha = HTTP.body_sha(body)
    {content_type, type} = ContentType.get_type(headers["Content-Type"], body)
    # TODO Check News.Util.DeadSHA

    temp_file = TempFile.write(sha, body)
    %Link{valid: true, url: URIFilter.uri_to_string(uri),
      status: status, domain: uri.host, sha: sha, file: temp_file, type: type,
      content_type: content_type, body: body}
  end

  defp request_result(uri, {:ok, status, headers, _}), do: %Link{valid: false, error: {:status,status}, status: status}
  defp request_result(uri, {:error, reason}), do: %Link{valid: false, error: {:fetch_error,reason}}

  # YouTube Embed
  defp process_result(struct, %URI{host: "youtube.com", path: "/watch", query: query}) do
    qs = URI.decode_query(query)
    if id = qs["v"] do
      html = embed_iframe("youtube", "//www.youtube.com/embed/#{id}")
      thumb = "https://img.youtube.com/vi/#{id}/default.jpg"
      %Link{struct | type: "video", preview: html, thumbnail_url: thumb}
    else struct end
  end

  # Vimeo Embed
  defp process_result(struct, uri=%URI{host: "vimeo.com"}) do
    case Regex.run(~r/\/(\d+)/, uri.path) do
      [_, id] ->
        html = embed_iframe("vimeo", "https://player.vimeo.com/video/#{id}?byline=0&portrait=0")

        # API Call because thumbnail
        api = HTTP.json_query("https://vimeo.com/api/v2/video/#{id}.json")
        thumb = if api.ok do
          body = List.first(api.body)
          body["thumbnail_small"]
        else nil end

        %Link{struct | type: "video", preview: html, thumbnail_url: thumb}
      _ -> struct
    end
  end

  # dailymotion Embed
  defp process_result(struct, uri=%URI{host: "dailymotion.com"}) do
    case Regex.run(~r/\/video\/([a-z0-9]+)_.*/, uri.path) do
      [_, id] ->
        html = embed_iframe("dailymotion", "//www.dailymotion.com/embed/video/#{id}")
        thumb = "http://www.dailymotion.com/thumbnail/video/#{id}"
        %Link{struct | type: "video", preview: html, thumbnail_url: thumb}
      _ -> struct
    end
  end

  # HTML
  defp process_result(struct=%Link{content_type: "text/html"}, uri) do
    struct
      |> Link.OEmbed.process_link
  end

  # GIFs
  # Note: we could also do this for every "image/*", and store height/width info
  defp process_result(struct=%Link{content_type: "image/gif"}, uri) do
    identify = :os.cmd(String.to_char_list("identify "<>struct.file)) |> List.to_string |> String.rstrip
    frames = String.split(identify, "\n")
    animated = length(frames) > 1
    [_, _, size | _] = String.split(List.first(frames), " ")
    [width, height] = String.split(size, "x")
    type = if animated, do: "animated", else: struct.type
    %Link{struct | type: type, thumbnail_url: struct.url}
  end

  defp process_result(struct, _uri) do
    struct
  end

  defp embed_iframe(class_prefix, src) do
    fullscreen = "webkitallowfullscreen mozallowfullscreen allowfullscreen"
    "<iframe class=\"embed-preview embed-#{class_prefix}\" src=\"#{src}\" \"#{fullscreen}\"></iframe>"
  end


end
