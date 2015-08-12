defmodule Mix.Tasks.News.BootstrapInitialData do
  use Mix.Task
  alias News.Repo
  alias News.Flag
  alias News.User

  @shortdoc "Bootstrap initial data."

  def run(_args) do
    Mix.Task.run "app.start", []
    Repo.insert!(%Flag{name: "admin", text: "A", class: "level", comment: "administrator"})
    Repo.insert!(%Flag{name: "submitter", text: "OP", class: "level", comment: "original poster"})
    Repo.insert!(%Flag{name: "mod", text: "M", class: "level", comment: "moderator"})
    system_user = Repo.insert!(%User{username: "system"})
    Flag.add_to_model(system_user, "admin", 1)
  end

  # We can define other functions as needed here.
end
