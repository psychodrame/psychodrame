defmodule News.Vote do
  use News.Web, :model

  schema "votes" do
    field :vote, :boolean, default: false
    field :votable_id, :integer
    field :votable_type, :string
    belongs_to :user, News.User

    timestamps

    field :return_to, :string, virtual: true
  end

  @required_fields ~w(vote votable_id votable_type)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_unique(:user_id, on: News.Repo, scope: [:votable_id, :votable_type])
  end

  def new_for_user(user) do
    build(user, :votes)
  end

  def self_vote_on(changeset, type, user) do
    vote = %__MODULE__{user_id: user.id, votable_type: type, votable_id: changeset.id, vote: true}
    vote = Repo.insert!(vote)
    News.Score.update_score_from_vote(vote)
    changeset
  end

end
