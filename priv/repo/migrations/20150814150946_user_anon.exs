defmodule News.Repo.Migrations.UserAnon do
  use Ecto.Migration

  def change do
    alter table(:users), do: add(:anon, :boolean, default: false)
  end
end
