defmodule News.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :about, :text
      add :email, :string
      add :hash, :string
      add :banned, :boolean, default: false
      add :admin, :boolean, default: false
      add :moderator, :boolean, default: false

      timestamps
    end

  end
end
