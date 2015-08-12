defmodule News.Repo.Migrations.UserLang do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :lang, :string
    end
  end
end
