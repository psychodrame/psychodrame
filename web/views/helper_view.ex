defmodule News.HelperView do
  use News.Web, :base_view

  def format_date(date) do
    alias Timex.Date
    alias Timex.DateFormat

    date = date
      |> Ecto.DateTime.to_erl
      |> Date.from
    text = date |> DateFormat.format!("%d/%m/%Y %H:%M", :strftime)
    iso = date |> DateFormat.format!("{ISOz}")

    render "_date.html", date: text, iso: iso
  end

  def user_link(user) do
    render "_user.html", user: user
  end

  def app_env(key, default \\ nil) do
    Application.get_env(:news, key, default)
  end

  def ui_settings(conn) do
    conn.assigns[:ui_settings]
  end

  def external_link(conn, title, opts) do
    target = if ui_settings(conn).external_new_tabs, do: "_blank", else: ""
    opts = opts
    |> Dict.put(:class, "external")
    |> Dict.put(:target, target)
    Phoenix.HTML.Link.link(title, opts)
  end

end
