defmodule News.Tag do
  use News.Web, :model
  alias News.Tagging
  alias News.Repo

  schema "tags" do
    field :name, :string
    field :description, :string
    has_many :taggings, News.Tagging
    has_many :stories, through: [:taggings, :story]

    timestamps
  end

  @required_fields ~w(name)
  @optional_fields ~w(description)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> validate_unique(:name, on: News.Repo, downcase: true)
    |> validate_format(:name, ~r/\A[0-9A-Za-z\:]+\z/i)
    |> validate_length(:name, min: 4, max: 35)
    |> cast(params, @required_fields, @optional_fields)
  end

  def find_by_name(tag_name) do
    query = from t in __MODULE__, where: t.name == ^tag_name
    Repo.one query
  end

  def create_or_find_by_name(tag_name) do
    query = from t in __MODULE__, where: t.name == ^tag_name
    tag = Repo.one query
    if tag do
      tag
    else
      Repo.insert!(%__MODULE__{name: tag_name})
    end
  end

  def url(tag) do
    "/t/"<>tag.name<>"/"
  end

  def submit_story(tag_name, story) do
    tag = create_or_find_by_name(tag_name)
    Repo.insert(%Tagging{tag_id: tag.id, story_id: story.id})
  end
end
