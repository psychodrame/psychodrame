defmodule News.CommentController do
  use News.Web, :controller

  alias News.Story
  alias News.Comment

  plug :scrub_params, "comment" when action in [:create, :update]
  plug News.Plug.Authenticate, [anon: true] when action in [:new, :create]
  plug News.Plug.Authenticate, [flags: ~w(admin)] when action in [:edit, :update, :delete]

  # New form for comment reply
  def new(conn, %{"comment_hash" => hash}) do
    comment = Comment.get_from_hashid(hash)
    if comment do
      comment = Repo.preload(comment, :user)
      comment = Repo.preload(comment, :story)
      changeset = Comment.changeset(%Comment{})
      render(conn, "new.html", comment: comment, changeset: changeset)
    else error_not_found(conn) end
  end

  # Commenting on a submission
  def create(conn, %{"comment" => comment_params}) do
    comment = %Comment{build(conn.assigns.current_user, :comments) | ip: conn.remote_ip}
    changeset = Comment.create_changeset(comment, comment_params)
    if changeset.valid? do
      comment = changeset
        |> Repo.insert!
        |> Comment.after_repo_insert(:create, conn)

      conn
      |> redirect(to: Story.url(comment.story))
    else
      render(conn, "new.html", changeset: changeset, comment: nil)
    end
  end

end
