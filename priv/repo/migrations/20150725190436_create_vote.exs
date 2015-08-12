defmodule News.Repo.Migrations.CreateVote do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :vote, :boolean, default: false
      add :votable_id, :integer
      add :votable_type, :string
      add :user_id, :integer

      timestamps
    end
    create index(:votes, [:user_id])
    create index(:votes, [:votable_id])
    create index(:votes, [:votable_type])

  end
end
