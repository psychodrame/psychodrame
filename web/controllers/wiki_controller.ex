defmodule News.WikiController do
  use News.Web, :controller

  defmodule Plug do
    def init(args), do: args
    def call(conn, _) do
      if conn.params["tag"] do
        # We have a tag: tag wiki.
        if tag = News.Repo.get_by(News.Tag, name: conn.params["tag"]) do
          assign(conn, :wiki_env, %{mode: :tag, tag: tag})
        else redirect(conn, to: "/") end
      else
        # No Tag: site wiki
        assign(conn, :wiki_env, %{mode: :site})
      end
    end
  end

  alias News.Wiki
  alias News.WikiRevision, as: Revision

  plug :scrub_params, "wiki" when action in [:create, :update]
  plug News.Plug.Authenticate, ~w(admin) when not action in [:index, :show]
  plug __MODULE__.Plug

  def index(conn, _params) do
    Logger.debug "Wiki#index -> wiki env #{inspect conn.assigns.wiki_env}"
    wikis = Repo.all from w in Wiki,
      preload: [revision: [:user]],
      where: is_nil(w.tag_id)
    render(conn, "index.html", wikis: wikis)
  end

  def new(conn, _params) do
    changeset = Wiki.changeset(%Wiki{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"wiki" => wiki_params}) do
    changeset = Wiki.changeset(%Wiki{ip: conn.remote_ip}, wiki_params)

    if changeset.valid? do
      Repo.insert!(changeset)

      conn
      |> put_flash(:info, "Wiki created successfully.")
      |> redirect(to: site_wiki_path(conn, :index))
    else
      render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => path}) do
    wiki = get_wiki(conn.assigns.wiki_env, path)
    render(conn, "show.html", wiki: wiki)
  end

  def edit(conn, %{"id" => path}) do
    wiki = get_wiki(conn.assigns.wiki_env, path)
    content = if wiki.revision_id, do: wiki.revision.content, else: ""
    changeset = Revision.changeset(%Revision{wiki_id: wiki.id, content: content})
    render(conn, "edit.html", wiki: wiki, changeset: changeset)
  end

  def update(conn, %{"id" => path, "wiki" => wiki_params}) do
    wiki = get_wiki(conn.assigns.wiki_env, path)
    rev_id = if wiki.revision_id, do: (wiki.revision.revision||1)+1, else: 1
    revision = %Revision{wiki_id: wiki.id, user_id: current_user(conn).id, revision: rev_id, ip: conn.remote_ip}
    changeset = Revision.changeset(revision, wiki_params)

    if changeset.valid? do
      revision = Repo.insert!(changeset)
        |> Revision.after_repo_insert(:create, conn)
      Repo.update!(%Wiki{wiki | revision_id: revision.id})

      conn
      |> put_flash(:info, "Revision created.")
      |> redirect(to: site_wiki_path(conn, :show, wiki.path))
    else
      render(conn, "edit.html", wiki: wiki, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    wiki = Repo.get!(Wiki, id)
    Repo.delete!(wiki)

    conn
    |> put_flash(:info, "Wiki deleted successfully.")
    |> redirect(to: site_wiki_path(conn, :index))
  end

  defp get_wiki(%{mode: :site}, path) do
    Repo.one! from w in Wiki,
    preload: [:user, revision: [:user]],
      where: w.path == ^path and is_nil(w.tag_id)
  end
  defp get_wiki(env=%{mode: :tag}, path) do
    Repo.one! from w in Wiki,
      preload: [:user, revision: [:user]],
      where: w.path == ^path and w.tag_id == ^env.tag.id
  end
end
