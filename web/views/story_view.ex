defmodule News.StoryView do
  use News.Web, :view
  alias News.Story

  def link_to_external?(conn, story) do
    external_link_types = ~w(link)
    internal_attr_types = ~w(image animated)
    !ui_settings(conn).list_links_story &&
    story.type in external_link_types &&
    not story.attrs["type"] in internal_attr_types &&
    !story.attrs["preview_html"]
  end

  def show_story_type_or_domain?(story) do
    type = Story.type_or_subtype(story)
    !(type == "link" && story.attrs && Map.has_key?(story.attrs, "domain"))
  end

  def thumbnail_for(conn, story), do: thumbnail_cache_url(story)

  defp thumb_img_tag(url), do: raw("<img src=\"#{url}\"/>")
  defp thumb_bitpixels_img_tag(url), do: url |> thumbnail_url |> thumb_img_tag
  #defp thumbnail_url(url), do: Application.get_env(:news, :thumbnail_url_prefix) <> URI.encode(url)
  defp thumbnail_cache_url(story), do: Story.link_cache_path(story, "thumb") |> thumb_img_tag
end
