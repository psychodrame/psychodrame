defmodule News.Repo.Migrations.CommentCommands do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :commands, :map
      add :meta, {:array, :string}
    end
  end
end
