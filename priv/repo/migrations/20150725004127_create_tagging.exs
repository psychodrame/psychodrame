defmodule News.Repo.Migrations.CreateTagging do
  use Ecto.Migration

  def change do
    create table(:taggings) do
      add :user_id, :integer
      add :tag_id, :integer
      add :story_id, :integer

      timestamps
    end
    create index(:taggings, [:user_id])
    create index(:taggings, [:tag_id])
    create index(:taggings, [:story_id])

  end
end
