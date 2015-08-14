defmodule News.Plug.CurrentUser do
  import Plug.Conn
  import Phoenix.Controller
  import News.I18n.Helper

  def init(state), do: state

  def call(conn, state) do
    if id = get_session(conn, :current_user), do: set_current_user(conn, id), else: conn
  end

  defp set_current_user(conn, user_id) do
    user = News.Repo.get(News.User, user_id)
    if user do
      assign(conn, :current_user, user)
    else
      conn
      |> put_session(:current_user, nil)
      |> put_flash(:error, t(conn, "alerts.invalid_session"))
      |> redirect(to: "/")
      |> halt
    end
  end

end
