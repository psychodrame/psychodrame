defmodule News.Repo.Migrations.CreateComment do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :content, :string
      add :comment_id, :integer
      add :user_id, :integer
      add :story_id, :integer

      timestamps
    end
    create index(:comments, [:comment_id])
    create index(:comments, [:user_id])
    create index(:comments, [:story_id])

  end
end
