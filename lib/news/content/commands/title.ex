defmodule News.Content.Commands.Title do
  @behaviour News.Content.Commands.Behaviour

  def commands, do: ~w(title)

  def validate(changeset, context=%{module: News.Comment}, _, args) do
    unless News.Flag.on_model?(context.user, "admin") do
      Ecto.Changeset.add_error(changeset, :text, News.td("commands.title_forbidden"))
    else changeset end
  end
  def validate(changeset, _, _, _) do
    Ecto.Changeset.add_error(changeset, :text, News.td("commands.title_error"))
  end

  def after_save(changeset, _, _, _), do: changeset

  def finalize(comment, context=%{module: News.Comment}, _, args) do
    comment = News.Repo.preload(comment, :story)
    title = Enum.join(args, " ")
    old_title = comment.story.title
    News.Repo.update!(%News.Story{comment.story | title: title})
    meta = News.td("commands.title_changed", [old: old_title, new: title])
    News.Flag.add_to_model(comment, "admin", comment.user_id)
    %News.Comment{comment | meta: [meta|comment.meta], flags: ["A"|comment.flags]}
  end
  def finalize(model, _, _, _), do: model
end
