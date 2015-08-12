defmodule News.Repo.Migrations.CreateStory do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add :title, :string
      add :type, :string
      add :link, :string
      add :content, :text
      add :user_id, :integer

      timestamps
    end
    create index(:stories, [:user_id])

  end
end
