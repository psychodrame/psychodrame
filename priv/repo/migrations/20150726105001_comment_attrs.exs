defmodule News.Repo.Migrations.CommentAttrs do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :attrs, :map
    end
  end
end
