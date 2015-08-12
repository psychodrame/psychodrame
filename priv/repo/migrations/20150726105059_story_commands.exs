defmodule News.Repo.Migrations.StoryCommands do
  use Ecto.Migration

  def change do
    alter table(:stories) do
      add :attrs, :map
      add :meta, {:array, :string}
      add :commands, :map
    end
  end
end
