defmodule News.Link.ManualEmbed do
  require Logger
  alias News.Link
  alias News.HTTP

  # YouTube Embed
  def process_link(link=%Link{final: false, url: %URI{host: "youtube.com", path: "/watch", query: query}}) do
    qs = URI.decode_query(query)
    if id = qs["v"] do
      html = embed_iframe("youtube", "//www.youtube.com/embed/#{id}")
      thumb = "https://img.youtube.com/vi/#{id}/default.jpg"
      %Link{link | type: "video", preview_html: html, thumbnail_url: thumb, final: true}
    else link end
  end

  # Vimeo Embed
  def process_link(link=%Link{final: false, url: %URI{host: "vimeo.com", path: path}}) do
    case Regex.run(~r/\/(\d+)/, path) do
      [_, id] ->
        html = embed_iframe("vimeo", "https://player.vimeo.com/video/#{id}?byline=0&portrait=0")

        # API Call because thumbnail
        api = HTTP.get_json("https://vimeo.com/api/v2/video/#{id}.json")
        thumb = if api.ok do
          body = List.first(api.body)
          body["thumbnail_small"]
        else nil end

        %Link{link | type: "video", preview_html: html, thumbnail_url: thumb, final: true}
      _ -> link
    end
  end

  # dailymotion Embed
  def process_link(link=%Link{final: false, url: %URI{host: "dailymotion.com", path: path}}) do
    case Regex.run(~r/\/video\/([a-z0-9]+)_.*/, path) do
      [_, id] ->
        html = embed_iframe("dailymotion", "//www.dailymotion.com/embed/video/#{id}")
        thumb = "http://www.dailymotion.com/thumbnail/video/#{id}"
        %Link{link | type: "video", preview_html: html, thumbnail_url: thumb, final: true}
      _ -> link
    end
  end

  def process_link(link) do
    Logger.debug "News.Link.ManualEmbed skipping for #{inspect link}"
    link
  end

  defp embed_iframe(class_prefix, src) do
    fullscreen = "webkitallowfullscreen mozallowfullscreen allowfullscreen"
    "<iframe class=\"embed-preview embed-#{class_prefix}\" src=\"#{src}\" \"#{fullscreen}\"></iframe>"
  end

end
