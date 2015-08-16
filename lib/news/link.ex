defmodule News.Link do
  @moduledoc "Link crawling / data extraction tool"

  alias __MODULE__
  alias News.HTTP
  alias News.RedisCache
  alias News.Util.URIFilter
  alias News.Util.ContentType
  alias News.Util.TempFile
  require Logger

  @max_content_length 3125000 # 25Mb
  @process_timeout 5000

  defstruct valid: false,
            error: nil,
            status: nil, # HTTP Status
            original_url: nil, # Original (user entered) URL
            url: nil, # Filtered URL
            url_string: nil, # Filtered URL as String
            thumbnail_url: nil, # Thumbnail URL if any
            domain: nil, # URL domain
            preview_url: nil, # URL preview (<img />, <audio />, <video />)
            preview_html: nil, # HTML preview
            sha: nil, # Body SHA
            body: nil, # Body
            file: nil, # Temporary file
            type: nil, # Media type
            content_type: nil, # Content type
            final: false # used by chained modules to halt processing

  @doc "Fetch and extracts `uri`"
  @spec process(String.t) :: %Link{}
  def process(uri) do
    filtered_uri = URIFilter.transform(URI.parse(uri))
    str_uri = URIFilter.uri_to_string(filtered_uri)
    link = %Link{valid: false, original_url: uri, url: filtered_uri, url_string: str_uri, domain: filtered_uri.host}

    RedisCache.cached(str_uri, fn() ->
      # Spawn process
      parent = self
      {pid, _ref} = spawn_monitor(fn() ->
        result = Link.request_and_process(link)
        send(parent, {:result, result})
      end)

      # Wait for result
      wait_for_result(link, pid)
    end)
  end

  def request_and_process(link) do
    link
      |> request_head(News.HTTP.head(link.url_string))
      |> process_link
  end

  # TODO: Extract Content-Type from header
  defp request_head(link, http=%HTTP{ok: true}) do
    length = Dict.get(http.headers, "Content-Length", "0") |> String.to_integer
    if length < @max_content_length do
      request_get(link, News.HTTP.head(link.url_string))
    else
      {content_type, type} = ContentType.get_type(http.headers["Content-Type"], "")
      %Link{link | valid: true, content_type: content_type, type: type}
    end
  end

  defp request_head(link, http) do
    Logger.warning "News.Link/process_head_request: failed request to #{link.url_string} -> #{inspect http}"
    %Link{link | valid: false, error: http.error || "invalid head"}
  end

  defp request_get(link, http=%HTTP{ok: true}) do
    sha = HTTP.body_sha(http.body)
    {content_type, type} = ContentType.get_type(http.headers["Content-Type"], http.body)
    # TODO Check News.Util.DeadSHA

    temp_file = TempFile.write(sha, http.body)
    %Link{link | valid: true, status: http.status, domain: link.url.host, sha: sha,
                 file: temp_file, type: type, content_type: content_type,
                 body: http.body}
  end

  defp request_get(link, http) do
    Logger.warning "News.Link/process_get_request: failed request to #{link.url_string} -> #{inspect http}"
    %Link{link | valid: false, error: http.error || "invalid get"}
  end

  # Don't process invalid links!
  defp process_link(link=%Link{valid: false}), do: link

  # HTML
  defp process_link(link=%Link{content_type: "text/html"}) do
    link
      |> Link.ManualEmbed.process_link
      |> Link.OEmbed.process_link
  end

  # GIFs
  # Note: we could also do this for every "image/*", and store height/width info
  defp process_link(link=%Link{content_type: "image/gif"}) do
    identify = :os.cmd(String.to_char_list("identify "<>link.file)) |> List.to_string |> String.rstrip
    frames = String.split(identify, "\n")
    animated = length(frames) > 1
    #[_, _, size | _] = String.split(List.first(frames), " ")
    #[width, height] = String.split(size, "x")
    type = if animated, do: "animated", else: link.type
    %Link{link | type: type, preview_url: link.url_string, thumbnail_url: link.url_string}
  end

  # Images - just set the url as thumbnail url too
  defp process_link(link=%Link{content_type: "image"<>_}) do
    %Link{link | preview_url: link.url_string, thumbnail_url: link.url_string}
  end

  # Catch-all, doing nothing
  defp process_link(link) do
    Logger.warn "News.Link/process_link: unmatched link, #{inspect link}"
    link
  end

  # TODO: Allow incremental updates from process and return it instead of an error when timeouting
  defp wait_for_result(link, pid) do
    link = receive do
      {:result, link} -> link
      _ -> wait_for_result(link, pid)
    after
      @process_timeout ->
        %Link{link | error: "processing timeout exceeded (5s)"}
    end
    if Process.alive?(pid), do: Process.exit(pid, :kill)
    link
  end

  defimpl Inspect, for: __MODULE__ do
    import Inspect.Algebra

    def inspect(link, opts) do
      url = link.original_url
      body = if Map.get(link, :body), do: :filtered, else: nil
      valid = if Map.get(link, :valid), do: "valid", else: "invalid"
      link = link
        |> Map.put(:body, body)
        |> Map.delete(:url)
        |> Map.delete(:original_url)
        |> Map.delete(:__struct__)
      concat ["News.Link: #{valid} [#{inspect url}] ", to_doc(link, opts)]
    end
  end


end
