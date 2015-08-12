defmodule News.Repo.Migrations.UserSettings do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :s_external_new_tabs, :boolean
      add :s_list_links_story, :boolean
      add :s_show_thumbnails, :boolean
    end
  end
end
