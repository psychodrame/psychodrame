defmodule News.ContentPipeline do
  @moduledoc """
    Content processing/extracting/formatting/…

    Entries:
      -> changeset — validating a model's field, with a given type
      -> format the field and cache as html in db
      -> after model save, run commands/callbacks
      -> ?
  """
  alias News.Content
  alias News.Comment
  alias News.Story
  alias News.WikiRevision
  alias News.Repo
  import Ecto.Changeset

  defmodule Behaviour do
    use Elixir.Behaviour
    defcallback changeset(Ecto.Changeset.t, Map.t) :: Ecto.Changeset.t
    defcallback after_save(Ecto.Changeset.t, Map.t) :: Ecto.Changeset.t
    defcallback finalize(Ecto.Model.t, Map.t) :: Ecto.Model.t
  end

  def pipelines, do: News.get_env(:content_pipelines)

  @spec changeset(Ecto.Changeset.t, String.t, String.t, Atom.t) :: Ecto.Changeset.t
  def changeset(changeset, field, pipeline_type, pipeline_action) do
    mods = pipelines[pipeline_type][pipeline_action]
    context = build_changeset_context(changeset, field, pipeline_type, pipeline_action)
    Enum.reduce(mods, changeset, fn(m, changeset) ->
      m.changeset(changeset, context)
    end)
  end

  @spec after_save(Ecto.Changeset.t, String.t, String.t, Atom.t) :: Ecto.Changeset.t
  def after_save(changeset, field, pipeline_type, pipeline_action) do
    if get_field(changeset, String.to_atom(field), nil) do
      mods = pipelines[pipeline_type][pipeline_action]
      context = build_changeset_context(changeset, field, pipeline_type, pipeline_action)
      changeset = Enum.reduce(mods, changeset, fn(m, changeset) -> m.after_save(changeset, context) end)
      changeset
    else
      changeset
    end
  end

  @spec finalize(Ecto.Model.t, String.t, String.t, Atom.t) :: Ecto.Changeset.t
  def finalize(model, field, pipeline_type, pipeline_action) do
    if Map.get(model, String.to_atom(field)) do
      mods = pipelines[pipeline_type][pipeline_action]
      context = build_model_context(model, field, pipeline_type, pipeline_action)
      model = preload_model(model)
      model = Enum.reduce(mods, model, fn(m, model) -> m.finalize(model, context) end)
      Repo.update!(model)
    else
      model
    end
  end

  defp build_changeset_context(changeset, field, pipeline_type, pipeline_action) do
    module = changeset.model.__struct__
    type = module.as_text
    value = get_field(changeset, String.to_atom(field), nil)
    %{pipeline_type: pipeline_type, pipeline_action: pipeline_action,
      module: module, type: type, field: String.to_atom(field), value: value}
    |> preload_changeset_model(changeset)
  end

  @preloads %{
    Story   => %{user_id: :user},
    Comment => %{user_id: :user, story_id: :story, comment_id: :comment},
    WikiRevision => %{wiki_id: :wiki, user_id: :user}
  }

  # Load current or future relationships of `changeset` in `context`.
  defp preload_changeset_model(ctx=%{module: module}, changeset) do
    Enum.reduce(@preloads[module], ctx, fn({key, name}, ctx) ->
      if id = Ecto.Changeset.get_field(changeset, key) do
        Map.put ctx, name, Repo.get(News.module_for(name), id)
      else ctx end
    end)
  end

  defp build_model_context(model, field, pipeline_type, pipeline_action) do
    module = model.__struct__
    type = module.as_text
    field = String.to_atom(field)
    value = Map.get(model, field)
    %{pipeline_type: pipeline_type, pipeline_action: pipeline_action,
      module: module, type: type, field: field, value: value}
  end

  @model_preloads %{
    Story => [:user, :taggings, :tags, :votes],
    Comment => [:user, :story, :comment],
    WikiRevision => [:wiki, :user]
  }
  defp preload_model(model=%{__struct__: module}) do
    Enum.reduce(@model_preloads[module], model, fn(name, model) -> Repo.preload(model, name) end)
  end

end
