defmodule News.Repo.Migrations.CommentContentIsTextNotString do
  use Ecto.Migration

  def change do
    alter table(:comments), do: modify(:content, :text)
  end
end
