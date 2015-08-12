defmodule News.Flag do
  use News.Web, :model

  schema "flags" do
    field :name, :string # Friendly flag name (css class, flag comment command)
    field :text, :string # Text to be displayed
    field :class, :string # Extra css classes
    field :comment, :string # Comment (title tag)
    field :link, :string # Optional link (for user profiles)
    field :hidden, :boolean, default: false # Hide on user profile

    timestamps
  end

  @required_fields ~w(name text comment)
  @optional_fields ~w(link class)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def add_to_model(target, flag_name, user_id \\ 1) do
    flag = Repo.get_by!(Flag, name: flag_name)
    flagging = build(target, :flaggings)
    flagging = %News.Flagging{flagging | flag_id: flag.id, user_id: user_id}
    Repo.insert(flagging)
  end

  def on_model?(model, flag) do
    model = Repo.preload(model, :flags)
    Enum.any?(model.flags, fn(f) -> f.name == flag end)
  end

  defmodule CommentSubmitterFlag do
    def add_to_comment(comment) do
      if comment.story.user_id == comment.user_id do
        News.Flag.add_to_model(comment, "submitter", comment.story.user_id)
      end
      comment
    end
  end

end
