defmodule News.Repo.Migrations.AddIp do
  use Ecto.Migration

  def change do
    alter table(:stories), do: add(:ip, :inet)
    alter table(:comments), do: add(:ip, :inet)
    alter table(:users), do: add(:ip_signup, :inet)
    alter table(:votes), do: add(:ip, :inet)
    alter table(:wikis), do: add(:ip, :inet)
    alter table(:wiki_revisions), do: add(:ip, :inet)
  end
end
