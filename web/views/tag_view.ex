defmodule News.TagView do
  use News.Web, :view
  alias News.Tag

  def tag_link(tag) do
    url = Tag.url(tag)
    style = "background-color:#{tag.color_bg};color:#{tag.color_fg}"
    link(tag.name, to: url, class: "tagged", style: style)
  end
end
