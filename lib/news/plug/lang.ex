defmodule News.Plug.Lang do
  import Plug.Conn
  import Phoenix.Controller

  def init(_state), do: _state

  def call(conn, _) do
    default = Application.get_env(:news, :lang, "en")
    lang = if conn.assigns[:current_user] do
      conn.assigns[:current_user].lang || default
    else default end
    assign(conn, :lang, lang)
  end
end
