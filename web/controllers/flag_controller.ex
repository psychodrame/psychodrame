defmodule News.FlagController do
  use News.Web, :controller

  alias News.Flag

  plug :scrub_params, "flag" when action in [:create, :update]
  plug News.Plug.Authenticate, [flags: ~w(admin)]

  def index(conn, _params) do
    flags = Repo.all(Flag)
    render(conn, "index.html", flags: flags)
  end

  def new(conn, _params) do
    changeset = Flag.changeset(%Flag{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"flag" => flag_params}) do
    changeset = Flag.changeset(%Flag{}, flag_params)

    if changeset.valid? do
      Repo.insert!(changeset)

      conn
      |> put_flash(:info, "Flag created successfully.")
      |> redirect(to: flag_path(conn, :index))
    else
      render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    flag = Repo.get!(Flag, id)
    render(conn, "show.html", flag: flag)
  end

  def edit(conn, %{"id" => id}) do
    flag = Repo.get!(Flag, id)
    changeset = Flag.changeset(flag)
    render(conn, "edit.html", flag: flag, changeset: changeset)
  end

  def update(conn, %{"id" => id, "flag" => flag_params}) do
    flag = Repo.get!(Flag, id)
    changeset = Flag.changeset(flag, flag_params)

    if changeset.valid? do
      Repo.update!(changeset)

      conn
      |> put_flash(:info, "Flag updated successfully.")
      |> redirect(to: flag_path(conn, :index))
    else
      render(conn, "edit.html", flag: flag, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    flag = Repo.get!(Flag, id)
    Repo.delete!(flag)

    conn
    |> put_flash(:info, "Flag deleted successfully.")
    |> redirect(to: flag_path(conn, :index))
  end
end
