defmodule News.HTTP do
  defstruct ok: nil, status: nil, headers: nil, body: nil, client: nil, error: nil

  def query(uri, agent \\ :check) do
    headers = [{"user-agent", News.user_agent(agent)}]
    options = [:insecure, {:follow_redirect, true}]
    case :hackney.request(:get, uri, headers, "", options) do
      {:ok, status=200, headers, client} ->
        {:ok, body} = :hackney.body(client)
        %__MODULE__{ok: true, status: status, headers: Enum.into(headers, %{}), body: body, client: client}
      {error, status, headers, client} ->
        %__MODULE__{ok: false, status: status, headers: Enum.into(headers, %{}), error: error, client: client}
    end
  end

  def json_query(uri, agent \\ :check) do
   query = query(uri, agent)
   if query.ok do
     %__MODULE__{query | body: Poison.decode!(query.body)}
   else query end
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
