defmodule News.User do
  use News.Web, :model

  schema "users" do
    field :username, :string
    field :email, :string
    field :hash, :string
    field :about, :string
    field :lang, :string
    field :score_stories, :float
    field :score_comments, :float
    field :score, :float, default: 0.0
    field :ip_signup, Ecto.INET
    field :anon, :boolean, default: false
    field :password, :string, virtual: true

    has_many :stories, News.Story
    has_many :comments, News.Comment
    has_many :flaggings, {"users_flaggings", News.Flagging}, foreign_key: :flagged_id
    has_many :flags, through: [:flaggings, :flag]
    has_many :votes, News.Vote

    timestamps

    # Settings fields
    field :s_external_new_tabs, :boolean, default: News.get_env(:ui_default_settings).external_new_tabs
    field :s_list_links_story, :boolean, default: News.get_env(:ui_default_settings).list_links_story
    field :s_show_thumbnails, :boolean, default: News.get_env(:ui_default_settings).show_thumbnails
  end

  @required_new_fields ~w(username password)
  @required_update_fields ~w()
  @optional_fields ~w(email about s_external_new_tabs s_list_links_story s_show_thumbnails)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model) do
    model |> cast(:empty, @required_new_fields, @optional_fields)
  end
  def changeset(:create, model, params) do
    model
    |> cast(params, @required_new_fields, @optional_fields)
    |> validate_unique(:username, on: News.Repo, downcase: true)
    |> validate_length(:username, min: 3, max: 35)
    |> validate_format(:username, ~r/\A[0-9A-Za-z\-_]+\z/i)
    |> validate_length(:password, min: 8)
  end
  def changeset(:update, model, params) do
    model
    |> cast(params, @required_update_fields, @optional_fields)
    |> validate_length(:about, max: 230)
  end

  def url(model), do: "/~#{model.username}"

  def build_vote(user, "1"), do: build_vote(user, true)
  def build_vote(user, "0"), do: build_vote(user, false)
  def build_vote(%__MODULE__{anon: true}, true), do: 0.5
  def build_vote(%__MODULE__{anon: true}, false), do: -0.2
  def build_vote(user, true), do: 1.0
  def build_vote(user, false), do: -1.0

end
