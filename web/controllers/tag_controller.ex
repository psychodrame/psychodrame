defmodule News.TagController do
  use News.Web, :controller

  alias News.Tag
  alias News.Story

  plug :scrub_params, "tag" when action in [:create, :update]
  plug News.Plug.Authenticate, ~w(admin) when action in [:edit, :create, :update, :delete]

  def index(conn, _params) do
    tags = Repo.all(Tag)
    render(conn, "index.html", tags: tags)
  end

  def show(conn, %{"name" => name}) do
    tag = Repo.one from t in Tag,
      where: t.name == ^name,
      preload: [:taggings]
    if tag do
      stories = Repo.all from story in Story,
        left_join: user in assoc(story, :user),
        left_join: comments in assoc(story, :comments),
        left_join: taggings in assoc(story, :taggings),
        left_join: tag in assoc(taggings, :tag),
        left_join: v in News.Vote, on: v.votable_id == story.id and v.votable_type == "story",
        where: taggings.tag_id == ^tag.id and story.score > 0,
        order_by: fragment("LOG(10,ABS(?)+1)*SIGN(?) + cast(extract(epoch from ?) as integer)/300000 DESC", story.score, story.score, story.inserted_at),
        preload: [user: user, tags: tag, comments: comments, votes: v]
      conn
        |> assign(:title, tag.name)
        |> render("show.html", tag: tag, stories: stories)
    else
      error_not_found conn
    end
  end

  def edit(conn, %{"id" => id}) do
    tag = Repo.get!(Tag, id)
    changeset = Tag.changeset(tag)
    render(conn, "edit.html", tag: tag, changeset: changeset)
  end

  def update(conn, %{"id" => id, "tag" => tag_params}) do
    tag = Repo.get!(Tag, id)
    changeset = Tag.changeset(tag, tag_params)

    if changeset.valid? do
      Repo.update!(changeset)

      conn
      |> put_flash(:info, "Tag updated successfully.")
      |> redirect(to: tag_path(conn, :index))
    else
      render(conn, "edit.html", tag: tag, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    tag = Repo.get!(Tag, id)
    Repo.delete!(tag)

    conn
    |> put_flash(:info, "Tag deleted successfully.")
    |> redirect(to: tag_path(conn, :index))
  end
end
