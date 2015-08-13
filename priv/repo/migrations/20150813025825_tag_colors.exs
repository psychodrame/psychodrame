defmodule News.Repo.Migrations.TagColors do
  use Ecto.Migration

  def change do
    alter table(:tags) do
      add :color_bg, :string
      add :color_fg, :string
    end
  end
end
