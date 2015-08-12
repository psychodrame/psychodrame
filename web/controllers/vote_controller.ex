defmodule News.VoteController do
  use News.Web, :controller

  alias News.Vote

  plug :scrub_params, "vote" when action in [:create, :update]
  plug News.Plug.Authenticate when action in [:create, :update]

  def create(conn, %{"vote" => vote_params}) do
    changeset = Vote.changeset(Vote.new_for_user(conn.assigns.current_user), vote_params)
    if changeset.valid? do
      vote = Repo.insert!(changeset)
    else
      v_id = vote_params["votable_id"] || 0
      v_tp = vote_params["votable_type"] || "lol"
      u_id = conn.assigns.current_user.id
      vote = Repo.one from vote in Vote,
        where: vote.votable_type == ^v_tp and vote.votable_id == ^v_id and vote.user_id == ^u_id
      if vote.vote == Ecto.Changeset.get_field(changeset, :vote) do
        Repo.delete(vote)
      else
        Repo.delete(vote)
        changeset = Vote.changeset(Vote.new_for_user(conn.assigns.current_user), vote_params)
        true = changeset.valid?
        vote = Repo.insert!(changeset)
      end
    end
    News.Score.update_score_from_vote(vote)
    back_path = vote_params["return_to"] || "/"
    redirect(conn, to: back_path)
  end

end
