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
                    :phoenix_ecto, :postgrex, :hackney, :tzdata]]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [
      {:phoenix, "~> 1.1.4"},
      {:phoenix_ecto, "~> 2.0.1"},
      #{:postgrex, ">= 0.0.0"},
      # FIXME Using postgrex master because it supports :inet (PR#92)
      {:postgrex, "~> 0.11.1", override: true},
      {:phoenix_html, "~> 2.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:cowboy, "~> 1.0"},
      {:comeonin, "~> 1.0"},
      {:cmark, "~> 0.5" },
      {:hashids, "~> 2.0"},
      {:slugger, "~> 0.0.1"},
      {:inflex, "~> 1.4"},
      {:timex, "~> 0.16"},
      {:linguist, "~> 0.1"},
      {:hackney, "~> 1.3"},
      {:floki, "~> 0.3"},
      {:exredis, "~> 0.2"},
      {:poolboy, "~> 1.4"},
   ]
  end
end
