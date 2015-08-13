defmodule News.Repo.Migrations.UserScores do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :score, :float
      add :score_stories, :float
      add :score_comments, :float
    end
  end
end
