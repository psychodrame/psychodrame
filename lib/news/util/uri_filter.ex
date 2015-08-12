defmodule News.Util.URIFilter do
  @moduledoc "Filter URIs..., somewhat ugly"

  @spec transform(URI.t | String.t) :: URI.t | String.t
  def transform(uri=%URI{}), do: filter(uri)
  def transform(uri) when is_binary(uri), do: to_string(filter(URI.parse(uri)))
  def uri_to_string(u=%URI{}) do
    base = u.scheme <> "://" <> u.host
    # Port
    base = if Enum.member?([80, 443], u.port), do: base, else: base<>":"<>u.port
    base = if u.path, do: base<>u.path, else: base
    base = if u.query, do: base<>"?"<>u.query, else: base
    base = if u.fragment, do: base<>"#"<>u.fragment, else: base
  end

  defp filter(uri=%{host: "www.reddit.com"}), do: filter(%{uri | host: "reddit.com"})
  defp filter(uri=%{host: "www.youtube.com"}), do: filter(%{uri | host: "youtube.com"})
  defp filter(uri=%{host: "www.vimeo.com"}), do: filter(%{uri | host: "vimeo.com"})
  defp filter(uri=%{host: "www.dailymotion.com"}), do: filter(%{uri | host: "dailymotion.com"})

  ### -- IMGUR
  @imgur_ignore_path ["/signin", "/random", "/register"]
  @imgur_ext_animated ["gifv", "m4v"]
  @imgur_ext_exception ["gif"]
  defp filter(uri=%{host: "imgur.com", scheme: "http"}), do: filter(%{uri | scheme: "https"})
  #defp filter(uri=%{host: "i.imgur.com", scheme: "https"}), do: filter(%{uri | scheme: "http"})
  #defp filter(uri=%{host: "imgur.com", path: "/gallery/" <> img}), do: %{uri | host: "i.imgur.com", path: "/#{img}.jpg"}
  #defp filter(uri=%{host: "imgur.com", path: "/a/" <> _}), do: uri
  #defp filter(uri=%{host: "imgur.com", path: path}) when path in @imgur_ignore_path, do: uri
  #defp filter(uri=%{host: "imgur.com", path: path}) do
  #  case String.split(path, "/") do
  #    [_, img]  -> filter(%{uri | host: "i.imgur.com", path: "/#{img}.jpg"})
      # This case is ignored because /topic/Bleh/ID can either be a ... image or a gallery. wut.
      #[_, _, _, img] -> %{uri | host: "i.imgur.com", path: "/#{img}.jpg"}
  #    _ -> uri
  #  end
  #end
  #defp filter(uri=%{host: "i.imgur.com", path: path}) do
#    path = String.split(path, "/") |> Enum.map(fn(p) -> String.split(p, ".") end) |> List.flatten
#    case path do
#      [_, img, format] when format in @imgur_ext_animated -> %{uri | path: "/#{img}.gif"}
#      [_, img, "jpeg"] -> %{uri | path: "/#{img}.jpg"}
#      [_, img, format] when format in @imgur_ext_exception -> %{uri | path: "/#{img}.#{format}"}
#      _ -> uri
#    end
#  end

  ### -- TUMBLR
  defp filter(uri=%{host: <<_ :: size(16), ".media.tumblr.com">>, scheme: "https"}), do: filter(%{uri | scheme: "http"})

  # -- Catch All
  defp filter(uri), do: uri

end
