defmodule News.Plug.Authenticate do
  import Plug.Conn
  import News.Router.Helpers
  import Phoenix.Controller
  import News.I18n.Helper

  def init(options \\ []), do: options

  def call(conn, options) do
    anon = Dict.get(options, :anon, false)
    required_flags = Dict.get(options, :flags, [])
    authenticate_request(conn, conn.assigns[:current_user], required_flags, anon)
  end

  # No user: gtfo
  defp authenticate_request(conn, nil, _, false), do: deny(conn, t(conn, "alerts.not_logged_in"), :account)
  # No user but anonymous is allowed: create user!
  defp authenticate_request(conn, nil, required_flags, true) do
    user = News.Repo.insert!(%News.User{anon: true, ip_signup: conn.remote_ip})
    conn = conn
      |> put_session(:current_user, user.id)
      |> assign(:current_user, user)
    authenticate_request(conn, conn.assigns[:current_user], required_flags, true)
  end

  # User and no constraint flags
  defp authenticate_request(conn, _, [], _), do: conn

  # User but constraints flags
  defp authenticate_request(conn, user, flags, _) do
    user = News.Repo.preload(user, :flags)
    user_flags = Enum.filter(user.flags, fn(flag) -> Enum.member?(flags, flag.name) end)
    unless Enum.empty?(user_flags) do
      conn
        |> assign(:authflag, List.first(user_flags))
    else
      deny(conn, t(conn, "alerts.missing_permissions"))
    end
  end

  defp deny(conn, reason, go_to \\ :index) do
    go_to = case go_to do
      :index -> root_path(conn, :frontpage)
      :account -> user_path(conn, :index)
    end
    conn
    |> put_flash(:error, reason)
    |> redirect(to: go_to)
    |> halt
  end
end
