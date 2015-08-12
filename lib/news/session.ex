defmodule News.Session do
  alias News.User
  alias News.Repo
  import Ecto.Model
  import Ecto.Query, only: [from: 2]

  def login(params) do
    username = String.downcase(params["username"])
    user = Repo.one(from u in User, where: fragment("lower(?)", u.username) == ^username)
    #user = Repo.get_by(User, username: String.downcase(params["username"]))
    case authenticate(user, params["password"]) do
      true -> {:ok, user}
      _    -> :error
    end
  end

  def current_user(conn) do
    conn.assigns[:current_user]
  end

  def logged_in?(conn), do: !!current_user(conn)

  defp authenticate(user, password) do
    case user do
      nil -> false
      _   -> Comeonin.Bcrypt.checkpw(password, user.hash)
    end
  end
end
