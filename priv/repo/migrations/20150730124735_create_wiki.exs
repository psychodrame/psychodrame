defmodule News.Repo.Migrations.CreateWiki do
  use Ecto.Migration

  def change do
    create table(:wikis) do
      add :path, :string
      add :custom_path, :boolean
      add :title, :string
      add :content_html, :string
      add :tag_id, :integer
      add :user_id, :integer
      add :revision_id, :integer
      timestamps
    end
    create index(:wikis, [:tag_id])
    create index(:wikis, [:user_id])

    create table(:wiki_revisions) do
      add :revision, :integer
      add :title, :string
      add :content, :text
      add :content_html, :text
      add :commands, :map
      add :attrs, :map
      add :meta, {:array, :string}
      add :wiki_id, :integer
      add :user_id, :integer
      timestamps
    end
    create index(:wiki_revisions, [:wiki_id])
    create index(:wiki_revisions, [:user_id])

    create table(:wikis_flaggings) do
      add :flagged_id, :integer
      add :flag_id, :integer
      add :user_id, :integer
      timestamps
    end
    create index(:wikis_flaggings, [:flagged_id])
    create index(:wikis_flaggings, [:flag_id])
    create index(:wikis_flaggings, [:user_id])

  end
end
