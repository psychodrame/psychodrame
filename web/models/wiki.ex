defmodule News.Wiki do
  use News.Web, :model

  schema "wikis" do
    field :path, :string
    field :custom_path, :boolean
    field :title, :string
    field :content_html, :string # cached
    field :ip, Ecto.INET
    belongs_to :tag, News.Tag
    belongs_to :user, News.User
    belongs_to :revision, News.WikiRevision
    has_many :flaggings, {"wikis_flaggings", News.Flagging}, foreign_key: :flagged_id
    has_many :flags, through: [:flaggings, :flag]
    has_many :revisions, News.WikiRevision

    timestamps
  end

  @required_fields ~w(title)
  @optional_fields ~w(custom_path path)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
