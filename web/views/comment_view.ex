defmodule News.CommentView do
  use News.Web, :view
  alias News.Comment

  def render("inline_form.html", %{type: "story", target: story, conn: conn}) do
    changeset = Comment.changeset(%Comment{story_id: story.id})
    assigns = %{type: "story", target: story, changeset: changeset, conn: conn}
    render("form.html", assigns)
  end

  def render("inline_form.html", %{type: "comment", target: comment, conn: conn}) do
    changeset = Comment.changeset(%Comment{comment_id: comment.id})
    assigns = %{type: "comment", target: comment, changeset: changeset, conn: conn}
    render("form.html", assigns)
  end

end
