defmodule News.Plug.Authenticate do
  import Plug.Conn
  import News.Router.Helpers
  import Phoenix.Controller
  import News.I18n.Helper

  def init(required_flags \\ []), do: required_flags

  def call(conn, required_flags) do
    authenticate_request(conn, conn.assigns[:current_user], required_flags)
  end

  # No user: gtfo
  defp authenticate_request(conn, nil, _), do: deny(conn, t(conn, "alerts.not_logged_in"), :account)

  # User and no constraint flags
  defp authenticate_request(conn, _, []), do: conn

  # User but constraints flags
  defp authenticate_request(conn, user, flags) do
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
