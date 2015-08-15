defmodule News.Link.OEmbed do
  @moduledoc "`News.Link` oEmbed extraction"

  alias News.Link
  alias News.HTTP
  require Logger

  @discovery_tags [
    "link[type=application/json+oembed]",
    "link[type=text/json+oembed]",
    #"link[type=application/xml+oembed]",
    #"link[type=text/xml+oembed]",
  ]

  @embeds_types %{
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
  # TODO Support pre-defined oEmbed endpoints without discovery
  # TODO Support noembed.com
  def process_link(link=%Link{}) do
    discovery = Enum.flat_map(@discovery_tags, fn(tag) -> Floki.find(link.body, tag) end)
    case List.first(discovery) do
      {"link", discovery, _} ->
        discovery = Enum.into(discovery, %{})
        process_oembed(link, discovery["href"], HTTP.json_query(discovery["href"]))
      _ -> link
    end
  end

  defp process_oembed(link, oembed_url, %{ok: true, body: oembed}) do
    oembed_url = URI.parse(oembed_url)
    type = @embeds_types[oembed_url.host] || link.type
    link = %Link{link | type: type}
    case oembed["type"] do
      "rich" ->
        %Link{link | preview: oembed["html"], thumbnail_url: oembed["thumbnail_url"]}
      "photo" ->
        %Link{link | type: "image", url: oembed["url"], thumbnail_url: oembed["thumbnail_url"]}
      _ ->
        Logger.warn "[News.Link] oEmbed unhandled type: #{inspect oembed}"
        link
    end
  end

  defp process_oembed(link, oembed_url, http) do
    Logger.warn "[News.Link] oEmbed failed request on #{inspect oembed_url} -> #{inspect http}"
    link
  end

end
