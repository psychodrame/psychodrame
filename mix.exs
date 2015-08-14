defmodule News.Mixfile do
  use Mix.Project

  def project do
    [app: :news,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {News, []},
     applications: [:phoenix, :phoenix_html, :cowboy, :logger,
                    :phoenix_ecto, :postgrex, :hackney]]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [
      {:phoenix, "~> 0.14"},
      {:phoenix_ecto, "~> 0.5"},
      #{:postgrex, ">= 0.0.0"},
      # FIXME Using postgrex master because it supports :inet (PR#92)
      {:postgrex, github: "ericmj/postgrex", override: true},
      {:phoenix_html, "~> 1.1"},
      {:phoenix_live_reload, "~> 0.4", only: :dev},
      {:cowboy, "~> 1.0"},
      {:comeonin, "~> 1.0"},
      {:cmark, "~> 0.5" },
      {:hashids, "~> 2.0"},
      {:slugger, "~> 0.0.1"},
      {:inflex, "~> 1.4.1"},
      {:timex, "~> 0.16.2"},
      {:linguist, "~> 0.1.5"},
      {:hackney, github: "benoitc/hackney"},
      {:floki, "~> 0.3.2"},
   ]
  end
end
