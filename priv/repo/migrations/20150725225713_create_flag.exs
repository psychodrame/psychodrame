defmodule News.Repo.Migrations.CreateFlag do
  use Ecto.Migration

  def change do
    create table(:flags) do

      add :name, :string
      add :text, :string
      add :class, :string
      add :comment, :string
      add :link, :string
      add :hidden, :boolean

      timestamps
    end

  end
end
