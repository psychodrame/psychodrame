defmodule News.ErrorView do
  use News.Web, :view

  def render("404.html", _assigns) do
    template("404: page not found.", _assigns)
  end

  def render("500.html", _assigns) do
    template("500: internal server error.", _assigns)
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end

  def template(text, assigns) do
    reqid = if assigns.conn do
      assigns.conn.resp_headers
      |> List.keyfind("x-request-id", 0, {"x-request-no-id", "00004000000200"})
      |> elem(1)
    else
      "0"
    end
    raw "<strong>"<>text<>"</strong>&nbsp;&nbsp;&nbsp;<small> &mdash; <a href='/'>go back</a></small><br /><br /><small><small>ref: "<>reqid<>"</small></small>"
  end
end
