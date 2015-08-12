defmodule News.Flagging do
  use News.Web, :model

  # :stories_flaggings, :comments_flaggings, :users_flaggings
  schema "abstract table: flaggings" do
    field :flagged_id, :integer
    belongs_to :flag, News.Flag
    belongs_to :user, News.User

    timestamps
  end

  @required_fields ~w(flagged_id user_id)
  @optional_fields ~w()

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
