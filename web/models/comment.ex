defmodule News.Comment do
  use News.Web, :model
  alias News.Story

  schema "comments" do
    field :content, :string
    field :content_html, :string
    field :commands, :map, default: %{}
    field :attrs, :map, default: %{}
    field :meta, {:array, :string}, default: []
    field :score, :float
    field :ip, Ecto.INET
    belongs_to :comment, News.Comment
    belongs_to :user, News.User
    belongs_to :story, News.Story
    has_many :flaggings, {"comments_flaggings", News.Flagging}, foreign_key: :flagged_id
    has_many :flags, through: [:flaggings, :flag]
    has_many :votes, News.Vote
    has_many :comments, News.Comment

    timestamps

    field :commentable_type, :string, virtual: true
    field :commentable_hash, :string, virtual: true
  end

  after_insert News.ContentPipeline, :after_save, ["content", "text", :create]
  after_update News.ContentPipeline, :after_save, ["content", "text", :update]

  @required_fields ~w(content)
  @optional_fields ~w()

  def as_text, do: "comment"

  def after_repo_insert(comment, action=:create, conn) do
    Repo.get!(Comment, comment.id)
      |> Repo.preload(:story)
      |> News.Vote.self_vote_on("comment", conn.assigns.current_user)
      |> News.Flag.CommentSubmitterFlag.add_to_comment
      |> News.Score.update_score
      |> News.ContentPipeline.finalize("content", "text", action)
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  @doc "Changeset for comment creation"
  def create_changeset(model, params) do
    model
      |> cast(params, @required_fields, @optional_fields)
      |> validate_and_set_commentable
      |> News.ContentPipeline.changeset("content", "text", :create)
    #  |> News.CommentCommands.Changeset.apply_to_changeset
  end

  @doc "Hashids utilities"
  def get_from_hashid(hashid), do: get_from_hashid(hashid, decode_id(hashid))
  def encode_id(model), do: Hashids.encode(News.hashids.comments, model.id)
  def decode_id(hash) do
    case Hashids.decode(News.hashids.comments, hash) do
      {:ok, [i]} -> i
      _ -> nil
    end
  end

  def url(model) do
    "/c/"<>encode_id(model)
  end

  defp validate_and_set_commentable(changeset) do
    validate_and_set_commentable(changeset,
                                 changeset.params["commentable_type"],
                                 changeset.params["commentable_hash"])
  end

  defp validate_and_set_commentable(changeset, "story", hash) do
    story = Story.get_from_hashid(hash)
    if story do
      put_change(changeset, :story_id, story.id)
    else
      add_error(changeset, :story_id, "does not exists")
    end
  end

  defp validate_and_set_commentable(changeset, "comment", hash) do
    comment = Comment.get_from_hashid(hash)
    if comment do
      changeset
        |> put_change(:comment_id, comment.id)
        |> put_change(:story_id, comment.story_id)
    else
      add_error(changeset, :comment_id, "does not exists")
    end
  end

  defp validate_and_set_commentable(changeset, unknown_type, _) do
    add_error(changeset, :commentable_type, "cannot comment on '#{unknown_type}'")
  end

  defp get_from_hashid(hashid, id) when is_integer(id), do: Repo.get!(Comment, id)
  defp get_from_hashid(hashid, _), do: nil
end
