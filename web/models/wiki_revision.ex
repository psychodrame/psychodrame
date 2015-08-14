defmodule News.WikiRevision do
  use News.Web, :model

  schema "wiki_revisions" do
    field :revision, :integer
    field :title, :string
    field :content, :string
    field :content_html, :string
    field :commands, :map, default: %{}
    field :attrs, :map, default: %{}
    field :meta, {:array, :string}, default: []
    field :ip, Ecto.INET
    belongs_to :wiki, News.Wiki
    belongs_to :user, News.User

    timestamps
  end

  after_insert News.ContentPipeline, :after_save, ["content", "text", :create]

  def as_text, do: "wikirev"

  def after_repo_insert(model, action=:create, conn) do
    Repo.get!(__MODULE__, model.id)
      |> Repo.preload(:wiki)
      |> News.ContentPipeline.finalize("content", "text", action)
  end

  @required_fields ~w(content)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> News.ContentPipeline.changeset("content", "text", :create)
  end
end
