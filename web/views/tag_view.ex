defmodule News.TagView do
  use News.Web, :view
  alias News.Tag

  def tag_link(tag) do
    url = Tag.url(tag)
    style = "background-color:rgba(#{tag.color_bg},0.6);border-color:rgba(#{tag.color_bg},1);color:#{tag.color_fg}"
    link(tag.name, to: url, class: "tagged", style: style)
  end
end
