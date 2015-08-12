defmodule News.Content.Commands.Tagging do
  @behaviour News.Content.Commands.Behaviour

  def commands, do: ~w(tag)

  def validate(changeset, context=%{module: News.Comment}, "tag", tags) do
    {_, comment_id} = Ecto.Changeset.fetch_field(changeset, :comment_id)
    if comment_id do
      Ecto.Changeset.add_error(changeset, :text, News.td("commands.tag_error"))
    else changeset end
  end
  def validate(changeset, context, cmd, tags), do: Ecto.Changeset.add_error(changeset, :text, "//tag: use the tags field!")

  def after_save(changeset, _, _, _), do: changeset

  def finalize(model, context=%{module: News.Comment}, "tag", tags) do
    tags = Enum.join(tags, ",")
      |> String.split(~r{[\W]})
      |> Enum.reject(fn(t) -> t == "" end)
      |> Enum.uniq
    for tag <- tags, do: News.Tag.submit_story(tag, model.story)
    meta = News.td("commands.tag_added", [tags: Enum.join(tags, ", ")])
    %News.Comment{model | meta: [meta|model.meta]}
  end
end
