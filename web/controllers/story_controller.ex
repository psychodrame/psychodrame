defmodule News.StoryController do
  use News.Web, :controller

  alias News.Story

  plug :scrub_params, "story" when action in [:create, :update]
  plug News.Plug.Authenticate when action in [:new, :create]
  plug News.Plug.Authenticate, ~w(admin) when action in [:edit, :update, :delete]

  # --- LISTINGS
  def frontpage(conn, _params) do
    stories = Repo.all from story in Story,
      left_join: user in assoc(story, :user),
      left_join: comments in assoc(story, :comments),
      left_join: taggings in assoc(story, :taggings),
      left_join: tag in assoc(taggings, :tag),
      left_join: v in News.Vote, on: v.votable_id == story.id and v.votable_type == "story",
      order_by: fragment("round(cast(log(greatest(abs(?), 1)) * sign(?) + (cast(extract(epoch from ?) as integer) - 1134028003) / 45000.0 as numeric), 7) DESC", story.score, story.score, story.inserted_at),
      where: story.score > 0,
      preload: [user: user, tags: tag, comments: comments, votes: v],
      select: story

    conn
      |> render("frontpage.html", stories: stories)
  end

  def latest(conn, _params) do
    stories = Repo.all from story in Story,
      left_join: user in assoc(story, :user),
      left_join: comments in assoc(story, :comments),
      left_join: taggings in assoc(story, :taggings),
      left_join: tag in assoc(taggings, :tag),
      left_join: v in News.Vote, on: v.votable_id == story.id and v.votable_type == "story",
      order_by: [desc: story.inserted_at],
      preload: [user: user, tags: tag, comments: comments, votes: v],
      select: story
    conn
      |> assign(:title, "latest")
      |> render("latest.html", stories: stories)
  end

  # ---- NEW / CREATE
  def new(conn, %{"type" => type}) when type in ["link","text"] do
    changeset = Story.changeset(%Story{})
    render(conn, "new.html", changeset: changeset, type: type)
  end
  def new(conn, %{"type" => _}), do: error_not_found(conn)
  def new(conn, _), do: redirect(conn, to: submit_path(conn, :new, "link"))

  def create(conn, %{"story" => story_params=%{"type" => type}}) when type in ["text", "link"] do
    new_story = build(conn.assigns.current_user, :stories)
    changeset = Story.changeset(new_story, story_params)

    if changeset.valid? do
      story = changeset
        |> Repo.insert!
        |> Story.after_repo_insert(:create, conn)

      if story_params["submit_to"] do
        tags = String.split(story_params["submit_to"], ~r{[\W]})
          |> Enum.reject(fn(t) -> t == "" end)
          |> Enum.uniq
        for tag <- tags, do: News.Tag.submit_story(tag, story)
      end

      conn
      |> redirect(to: Story.url(story))
    else
      render(conn, "new.html", changeset: changeset, type: type)
    end
  end

  # /s/:hash/:slug
  def show(conn, %{"hash" => hash, "slug" => slug}) do
    id = Story.decode_id(hash)
    if id do
      show(conn, %{"id" => id, "slug" => slug})
    else
      error_not_found(conn)
    end
  end
  # /s/:hash
  def show(conn, %{"hash" => hash}), do: show(conn, %{"hash" => hash, "slug" => "no"})
  # /stories/:id/:slug
  def show(conn, _params=%{"id" => id, "slug" => slug}) do
    story = Repo.get! from(story in Story,
                            left_join: user in assoc(story, :user),
                            left_join: comments in assoc(story, :comments),
                            left_join: taggings in assoc(story, :taggings),
                            left_join: tag in assoc(taggings, :tag),
                            left_join: v in News.Vote, on: v.votable_id == story.id and v.votable_type == "story",
                            left_join: cv in News.Vote, on: v.votable_id == comments.id and v.votable_type == "comment",
                            preload: [user: user, tags: tag, votes: v, comments: [:user, :comment]],
                            order_by: fragment("LOG(10,ABS(?)+1)*SIGN(?) + cast(extract(epoch from ?) as integer)/300000 DESC", comments.score, comments.score, comments.inserted_at),
                          ), id
    comments = Enum.group_by(story.comments, fn(comment) -> comment.comment_id end)
    if Story.slug(story) == slug do
      Logger.debug "Story: #{inspect story}"
      conn
        |> assign(:canonical, Story.url(story))
        |> assign(:meta_keywords, Enum.join(Enum.map(story.tags, fn(tag) -> tag.name end), ", "))
        |> assign(:title, story.title)
        |> render("show.html", story: story, comments: comments)
    else
      redirect(conn, to: Story.url(story))
    end
  end
  # /stories/:id
  def show(conn, %{"id" => id}), do: show(conn, %{"id" => id, "slug" => "no"})

  def edit(conn, %{"id" => id}) do
    story = Repo.get!(Story, id)
    changeset = Story.changeset(story)
    render(conn, "edit.html", story: story, changeset: changeset)
  end

  def update(conn, %{"id" => id, "story" => story_params}) do
    story = Repo.get!(Story, id)
    changeset = Story.changeset(story, story_params)

    if changeset.valid? do
      Repo.update!(changeset)

      conn
      |> put_flash(:info, "Story updated successfully.")
      |> redirect(to: story_path(conn, :index))
    else
      render(conn, "edit.html", story: story, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    story = Repo.get!(Story, id)
    Repo.delete!(story)

    conn
    |> put_flash(:info, "Story deleted successfully.")
    |> redirect(to: story_path(conn, :index))
  end
end
