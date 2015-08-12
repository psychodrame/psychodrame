defmodule News.Repo.Migrations.CreateTag do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string
      add :description, :string

      timestamps
    end

  end
end
