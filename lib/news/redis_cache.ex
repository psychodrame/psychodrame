defmodule News.RedisCache do
  @moduledoc "Basic structure cache in Redis"
  alias Exredis.Api, as: Redis

  @default_expire 86400
  @prefix "news:rcache:"

  def cached(key, expiry \\ @default_expire, fun) do
    if value = get(key) do
      value
    else
      set(key, expiry, fun.())
    end
  end

  def get(key) do
    case :poolboy.transaction(:redis, fn(redis) -> Redis.get(key(key)) end) do
      :undefined -> nil # WTF Exredis? :)
      binary when is_binary(binary) -> :erlang.binary_to_term(binary)
    end
  end

  def set(key, expiry, value) do
    binary = :erlang.term_to_binary(value)
    :poolboy.transaction(:redis, fn(redis) ->
      Redis.set(redis, key(key), binary)
      Redis.expire(redis, key(key), expiry)
    end)
    value
  end

  defp key(key), do: @prefix <> key

end
