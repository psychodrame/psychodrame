defmodule News.Repo.Migrations.UniqueIndexes do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;"
    alter table(:users) do
      modify(:username, :citext)
    end
    create unique_index(:users, [:username])

    alter table(:stories) do
      modify(:link, :citext)
    end
    create unique_index(:stories, [:link])

    alter table(:tags) do
      modify(:name, :citext)
    end
    create unique_index(:tags, [:name])

    create unique_index(:votes, [:user_id, :votable_id, :votable_type], name: :votes_unique_index)

  end
end
