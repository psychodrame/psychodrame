defmodule News.Score do
  alias News.Repo
  alias News.Vote
  alias News.Story
  alias News.Comment
  alias News.User
  import Ecto.Model
  import Ecto.Query, only: [from: 2]

  @modules %{"story" => Story, "comment" => Comment}


  def update_score(m=%Comment{}), do: update_score("comment", m)
  def update_score(m=%Story{}), do: update_score("story", m)
  def update_score(m=%User{}), do: update_user_score(m)

  def update_score(type, model) when is_binary(type) do
    score = Repo.all from v in Vote,
      where: v.votable_type == ^type and v.votable_id == ^model.id,
      group_by: v.vote,
      select: {v.vote, count(v.vote)}
    score = (score[:true] || 0) - (score[:false] || 0)
    model = Repo.update!(Map.put(model, :score, score))
    update_user_score(model.user_id)
    model
  end

  def update_score_from_vote(vote) do
    type = vote.votable_type
    model = Repo.get!(@modules[type], vote.votable_id)
    score = Repo.all from v in Vote,
      where: v.votable_type == ^type and v.votable_id == ^model.id,
      group_by: v.vote,
      select: {v.vote, count(v.vote)}
    score = (score[:true] || 0) - (score[:false] || 0)
    model = Repo.update!(Map.put(model, :score, score))
    update_user_score(model.user_id)
    model
  end

  def update_story_score(story) when is_integer(story), do: update_story_score(Repo.get!(Story, story))
  def update_story_score(story) do
    score = Repo.all from v in Vote,
      where: v.votable_type == "story" and v.votable_id == ^story.id,
      group_by: v.vote,
      select: {v.vote, count(v.vote)}
    score = (score[:up] || 0) - (score[:down] || 0)
    Repo.update!(%Story{story | score: score})
  end

  def update_user_score(id) when is_integer(id), do: update_user_score(Repo.get!(User, id))
  def update_user_score(user=%User{}) do
    stories = Repo.all from story in Story, where: story.user_id == ^user.id
    comments = Repo.all from story in Comment, where: story.user_id == ^user.id
    story_score = Enum.reduce(stories, 0.0, fn(story, acc) -> acc + (story.score||0) end)
    comm_score = Enum.reduce(comments, 0.0, fn(comment, acc) -> acc + (comment.score||0) end)
    score = comm_score + (story_score*0.5)
    Repo.update!(%User{user | score: score, score_stories: story_score, score_comments: comm_score})
  end
end
