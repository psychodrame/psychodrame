defmodule News.LayoutView do
  use News.Web, :view

  @title_separator "·"
  def page_title(conn) do
    base_title = Application.get_env(:news, :title, "")
    titles = if conn.assigns[:title] do
      [conn.assigns[:title], base_title]
    else [base_title] end
    Enum.join(titles, " #{@title_separator} ")
  end

end
