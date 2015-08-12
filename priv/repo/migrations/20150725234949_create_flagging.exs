defmodule News.Repo.Migrations.CreateFlagging do
  use Ecto.Migration

  def change do
    create table(:stories_flaggings) do
      add :flagged_id, :integer
      add :flag_id, :integer
      add :user_id, :integer
      timestamps
    end
    create index(:stories_flaggings, [:flagged_id])
    create index(:stories_flaggings, [:flag_id])
    create index(:stories_flaggings, [:user_id])
    create table(:comments_flaggings) do
      add :flagged_id, :integer
      add :flag_id, :integer
      add :user_id, :integer
      timestamps
    end
    create index(:comments_flaggings, [:flagged_id])
    create index(:comments_flaggings, [:flag_id])
    create index(:comments_flaggings, [:user_id])
    create table(:users_flaggings) do
      add :flagged_id, :integer
      add :flag_id, :integer
      add :user_id, :integer
      timestamps
    end
    create index(:users_flaggings, [:flagged_id])
    create index(:users_flaggings, [:flag_id])
    create index(:users_flaggings, [:user_id])

  end
end
