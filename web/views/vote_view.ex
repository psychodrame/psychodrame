defmodule News.VoteView do
  use News.Web, :view
  alias News.Vote
  import Ecto.Model
  import Ecto.Query, only: [from: 2]


  def vote_form_for(model, conn, display \\ "flex") do
    [type, id] = vote_meta_for(model)
    vote = %Vote{votable_type: type, votable_id: id, return_to: conn.request_path}
    changeset = Vote.changeset(vote)
    voted = previous_vote_for(type, id, conn.assigns[:current_user])
    render "vote.html", changeset: changeset, conn: conn, voted: voted, display: display, model: model
  end

  defp vote_meta_for(%{__struct__: News.Story, id: id}), do: ["story", id]
  defp vote_meta_for(%{__struct__: News.Comment, id: id}), do: ["comment", id]
  defp previous_vote_for(type, id, %{__struct__: News.User, id: user_id}) do
    vote = News.Repo.all from v in Vote,
      where: v.votable_id == ^id and v.votable_type == ^type and v.user_id == ^user_id,
      limit: 1
    unless Enum.empty?(vote) do
      vote = List.first(vote)
      %{up: Vote.up?(vote), down: Vote.down?(vote), vote: vote}
    else previous_vote_for(nil, nil, nil) end
  end
  defp previous_vote_for(_, _, _), do: %{up: false, down: false, vote: nil}
end
