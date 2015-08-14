defmodule News.UserController do
  use News.Web, :controller

  alias News.User
  alias News.UserPassword
  alias News.Repo
  alias News.Session

  plug :scrub_params, "user" when action in [:create, :update, :login]
  plug News.Plug.Authenticate, [flags: ~w(admin)] when action in [:delete]

  # Login/Register page
  def index(conn, _params) do
    if logged_in?(conn) && !current_user(conn).anon do
      changeset = User.changeset(current_user(conn))
      conn
        |> assign(:title, t(conn, "user.your_account"))
        |> render("edit.html", user: current_user(conn), changeset: changeset)
    else
      new_changeset = User.changeset(%User{})
      conn
        |> assign(:title, t(conn, "login"))
        |> render("index.html", new_changeset: new_changeset)
    end
  end

  def login(conn, %{"user" => user_params}) do
    case Session.login(user_params) do
      {:ok, user} ->
        conn
          |> put_session(:current_user, user.id)
          |> put_flash(:info, News.td("authentication.success"))
          |> redirect(to: "/")
      _ ->
        conn
          |> put_flash(:error, News.td("authentication.failure"))
          |> redirect(to: "/account")
    end
  end

  def logout(conn, _) do
    conn = if get_session(conn, :current_user) do
      put_session(conn, :current_user, nil)
    else conn end
    redirect(conn, to: "/")
  end

  def new(conn, _params) do
    changeset = User.changeset(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset(:create, %User{ip_signup: conn.remote_ip}, user_params)

    if changeset.valid? do
      new_user = UserPassword.generate_password_and_store_user(changeset)

      conn
      |> put_flash(:info, t(conn, "user.welcome"))
      |> put_session(:current_user, new_user.id)
      |> redirect(to: root_path(conn, :frontpage))
    else
      render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"username" => ["~"<>username]}) do
    username = String.downcase(username)
    query = from u in User, where: fragment("lower(?)", u.username) == ^username
    user = Repo.one! query
    user = Repo.preload user, :flags
    conn
      |> assign(:title, user.username)
      |> render("show.html", user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Repo.get!(User, id)
    if current_user(conn).id == user.id do
      changeset = User.changeset(:update, user, user_params)

      if changeset.valid? do
        Repo.update!(changeset)

        conn
        |> redirect(to: user_path(conn, :index))
      else
        render(conn, "edit.html", user: user, changeset: changeset)
      end
    else
      conn
      |> put_flash(:info, t(conn, "alerts.missing_permissions"))
      |> redirect(to: "/")
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Repo.get!(User, id)
    Repo.delete!(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end
end
