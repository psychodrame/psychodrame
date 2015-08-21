defmodule News.Story do
  use News.Web, :model

  schema "stories" do
    field :title, :string
    field :type, :string
    field :link, :string
    field :content, :string
    field :content_html, :string
    field :commands, :map, default: %{}
    field :attrs, :map, default: %{}
    field :meta, {:array, :string}, default: []
    field :score, :float
    field :ip, Ecto.INET
    belongs_to :user, News.User
    has_many :taggings, News.Tagging
    has_many :tags, through: [:taggings, :tag]
    has_many :comments, News.Comment
    has_many :flaggings, {"stories_flaggings", News.Flagging}, foreign_key: :flagged_id
    has_many :flags, through: [:flaggings, :flag]
    has_many :votes, News.Vote, foreign_key: :votable_id

    timestamps

    field :submit_to, :string, virtual: true
  end

  after_insert News.ContentPipeline, :after_save, ["content", "text", :create]
  #after_update News.ContentPipeline, :after_save, ["content", "text", :update]
  after_insert News.ContentPipeline, :after_save, ["link", "link", :create]
  #after_update News.ContentPipeline, :after_save, ["link", "link", :update]

  @required_fields ~w(title type user_id)
  @optional_fields ~w(link content)
  @allowed_link_schemes ~w(http https)

  def as_text, do: "story"

  def after_repo_insert(comment, action=:create, conn) do
    Repo.get!(Story, comment.id)
      |> News.Vote.self_vote_on("story", conn.assigns.current_user)
      |> News.Score.update_score
      |> News.ContentPipeline.finalize("content", "text", action)
      |> News.ContentPipeline.finalize("link", "link", action)
  end

  def type_or_subtype(story), do: story.attrs["type"] || story.type

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  # No params - invalid changeset returned
  def changeset(model) do
    model
      |> cast(:empty, @required_fields, @optional_fields)
  end

  def changeset(model, params=%{"type" => "link"}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:title, min: 5, max: 350)
    |> validate_unique(:link, on: News.Repo, downcase: true, message: "has already been submitted")
    |> News.ContentPipeline.changeset("link", "link", :create)
    #|> validate_link_and_extract_attributes
  end

  def changeset(model, params=%{"type" => "text"}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:content, min: 5)
    |> News.ContentPipeline.changeset("content", "text", :create)
  end

  def slug(model) do
    Slugger.slugify_downcase(model.title, ?_)
  end

  # Note: this is totally dumb and supposed to be used only when the link can be cached
  def link_cache_path(model, path \\ "cached") do
    if model.link do
      extension = if path == "thumb", do: ".jpg", else: Path.extname(model.link)
      static_host_base <> url(model) <> path <> extension
    end
  end

  def encode_id(model), do: Hashids.encode(News.hashids.stories, model.id)

  def url(model) do
    "/s/"<>encode_id(model)<>"/"<>slug(model)<>"/"
  end

  def preview_html_url(model), do: static_host_base <> url(model) <> "preview_html"

  def get_from_hashid(hashid) do
    get_from_hashid(hashid, decode_id(hashid))
  end

  def decode_id(hash) do
    case Hashids.decode(News.hashids.stories, hash) do
      {:ok, [i]} -> i
      _ -> nil
    end
  end

  def thumbnail_url(story=%Story{attrs: %{"thumbnail_url" => url}}) when not is_nil(url), do: url
  def thumbnail_url(story=%Story{type: "link"}), do: thumb_bitpixels(story.link)
  def thumbnail_url(story), do: thumb_bitpixels("http://psychodra.me#{News.Story.url(story)}")
  defp thumb_bitpixels(url), do: Application.get_env(:news, :thumbnail_url_prefix) <> URI.encode(url)

  defp get_from_hashid(hashid, id) when is_integer(id), do: Repo.get!(Story, id)
  defp get_from_hashid(hashid, _), do: nil

  defp static_host_base, do: News.get_env(:static_host, "")


end
