defmodule News.Tag do
  use News.Web, :model
  alias News.Tagging
  alias News.Repo
  require Logger

  schema "tags" do
    field :name, :string
    field :description, :string
    field :color_bg, :string
    field :color_fg, :string
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
    color = News.Util.RandomColor.get
    color_bg = Enum.join(color[:rgb], ",")
    color_fg = if color[:dark], do: "white", else: "black"
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_unique(:name, on: News.Repo, downcase: true)
    |> validate_format(:name, ~r/\A[0-9A-Za-z\:]+\z/i)
    |> validate_length(:name, min: 4, max: 35)
    |> put_change(:color_bg, color_bg)
    |> put_change(:color_fg, color_fg)
  end

  def find_by_name(tag_name) do
    tag_name = String.downcase(tag_name)
    query = from t in __MODULE__, where: fragment("lower(?)", t.name) == ^tag_name
    Repo.one query
  end

  def create_or_find_by_name(tag_name) do
    tag = find_by_name(tag_name)
    if tag do
      tag
    else
      changeset = __MODULE__.changeset(%__MODULE__{}, %{"name" => tag_name})
      if changeset.valid? do
        Repo.insert!(changeset)
      else
        Logger.error "Invalid changeset for tag create: #{inspect changeset}"
        false
      end
    end
  end

  def url(tag) do
    "/t/"<>tag.name<>"/"
  end

  def submit_story(tag_name, story) do
    if tag = create_or_find_by_name(tag_name) do
      Repo.insert(%Tagging{tag_id: tag.id, story_id: story.id})
    else false end
  end
end
