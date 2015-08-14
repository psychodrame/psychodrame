defmodule News.Repo.Migrations.VoteAsFloat do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE votes ALTER COLUMN vote DROP DEFAULT;"
    execute "ALTER TABLE votes ALTER COLUMN vote TYPE double precision USING (vote::int::double precision);"
    execute "UPDATE votes SET vote = -1.0 WHERE vote = 0;"

    execute "ALTER TABLE stories ALTER COLUMN score DROP DEFAULT;"
    execute "ALTER TABLE stories ALTER COLUMN score TYPE double precision USING (score::int::double precision);"

    execute "ALTER TABLE comments ALTER COLUMN score DROP DEFAULT;"
    execute "ALTER TABLE comments ALTER COLUMN score TYPE double precision USING (score::int::double precision);"
  end
end
