defmodule News.Repo.Migrations.Score do
  use Ecto.Migration

  def change do
    alter table(:stories), do: add(:score, :integer)
    alter table(:comments), do: add(:score, :integer)
  end
end
