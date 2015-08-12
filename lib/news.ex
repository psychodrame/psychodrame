defmodule News do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(News.Endpoint, []),
      # Start the Ecto repository
      worker(News.Repo, []),
      # Here you could define other workers and supervisors as children
      # worker(News.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: News.Supervisor]

    hashids = Enum.reduce(Application.get_env(:news, :hashid_salts), %{}, fn({key, salt}, acc) ->
      Map.put(acc, key, Hashids.new([salt: salt, min_len: 5]))
    end)
    Application.put_env(:news, :hashids, hashids)
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    News.Endpoint.config_change(changed, removed)
    :ok
  end

  def get_env(key, default \\ nil), do: Application.get_env(:news, key, default)

  def hashids, do: Application.get_env(:news, :hashids)

  def td(p, b \\ []), do: News.I18n.Helper.td(p,b)

  @modules_string_map %{
    "story"   => News.Story,
    "comment" => News.Comment,
    "user"    => News.User,
    "wiki"    => News.Wiki,
    "wikirev" => News.WikiRevision,
  }
  def module_for(atom) when is_atom(atom), do: module_for(Atom.to_string(atom))
  def module_for(string), do: @modules_string_map[string]
  def name_for_module(module), do: throw(:lol)

  def version, do: "0.0"

  @user_agent_bots %{
    check: ["CheckBot", "User Submission Crawler"],
    cache: ["CacheBot", "User Proxy/Cache"],
  }
  def user_agent(bot) do
    [name, comment] = @user_agent_bots[bot]
    "Mozilla/5.0 (compatible; Erlang) Psychodrame#{name}/#{version} (#{comment}; #{Application.get_env(:news,:title)}; +#{Application.get_env(:news,:crawler_info_url)})"
  end

end
