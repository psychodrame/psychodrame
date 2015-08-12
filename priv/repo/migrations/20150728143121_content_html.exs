defmodule News.Repo.Migrations.ContentHtml do
  use Ecto.Migration

  def change do
    alter table(:stories), do: add(:content_html, :text)
    alter table(:comments), do: add(:content_html, :text)
  end
end
