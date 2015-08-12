defmodule News.Score do
  alias News.Repo
  alias News.Vote
  alias News.Story
  alias News.Comment
  import Ecto.Model
  import Ecto.Query, only: [from: 2]

  @modules %{"story" => Story, "comment" => Comment}


  def update_score(m=%Comment{}), do: update_score("comment", m)
  def update_score(m=%Story{}), do: update_score("story", m)

  def update_score(type, model) when is_binary(type) do
    score = Repo.all from v in Vote,
      where: v.votable_type == ^type and v.votable_id == ^model.id,
      group_by: v.vote,
      select: {v.vote, count(v.vote)}
    score = (score[:true] || 0) - (score[:false] || 0)
    Repo.update!(Map.put(model, :score, score))
  end

  def update_score_from_vote(vote) do
    type = vote.votable_type
    model = Repo.get!(@modules[type], vote.votable_id)
    score = Repo.all from v in Vote,
      where: v.votable_type == ^type and v.votable_id == ^model.id,
      group_by: v.vote,
      select: {v.vote, count(v.vote)}
    score = (score[:true] || 0) - (score[:false] || 0)
    Repo.update!(Map.put(model, :score, score))
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
end
