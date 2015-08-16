defmodule News.HTTP do
  defstruct ok: nil, status: nil, headers: nil, body: nil, client: nil, error: nil

  def get(uri, agent \\ :check), do: query(uri, :get, agent)
  def head(uri, agent \\ :check), do: query(uri, :get, agent)

  def get_json(uri, agent \\ :check) do
   query = query(uri, :get, agent)
   if query.ok do
     %__MODULE__{query | body: Poison.decode!(query.body)}
   else query end
  end

  def query(uri, method, agent \\ :check) do
    headers = [{"user-agent", News.user_agent(agent)}]
    options = [:insecure, {:follow_redirect, true}]
    case :hackney.request(method, uri, headers, "", options) do
      {:ok, status=200, headers, client} ->
        body = if method == :get do
          {:ok, body} = :hackney.body(client)
          body
        else nil end
        %__MODULE__{ok: true, status: status, headers: Enum.into(headers, %{}), body: body, client: client}
      {error, status, headers, client} ->
        %__MODULE__{ok: false, status: status, headers: Enum.into(headers, %{}), error: error, client: client}
    end
  end

  def body_sha(body) do
    digest = :crypto.hash_init(:sha)
      |> :crypto.hash_update(body)
      |> :crypto.hash_final
    size = bit_size(digest)
    << n :: big-unsigned-integer-size(size) >> = digest
    format = '~' ++ :erlang.integer_to_list(:erlang.div(size, 4)) ++ '.16.0b'
    sha = :lists.flatten(:io_lib.format(format, [n])) |> List.to_string
  end

end
