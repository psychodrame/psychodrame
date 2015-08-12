defmodule News.Content.Commands.Flagging do
  @behaviour News.Content.Commands.Behaviour

  def commands, do: ~w(flag)

  def validate(changeset, context=%{module: News.WikiRevision}, _, [flag]) do
    unless News.Flag.on_model?(context.user, flag) do
      Ecto.Changeset.add_error(changeset, context.field, News.td("commands.flag_error", [flag: flag]))
    else changeset end
  end

  def validate(changeset, context, _, [flag]) do
    unless News.Flag.on_model?(context.user, flag) do
      Ecto.Changeset.add_error(changeset, context.field, News.td("commands.flag_error", [flag: flag]))
    else changeset end
  end

  def after_save(changeset, _, _, _), do: changeset

  def finalize(model, context=%{module: News.WikiRevision}, _, [flag]) do
    News.Flag.add_to_model(model.wiki, flag, model.user_id)
    model
  end

  def finalize(model, context, _, [flag]) do
    News.Flag.add_to_model(model, flag, model.user_id)
    model
  end
end
