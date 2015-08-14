defmodule Ecto.INET do
  @behaviour Ecto.Type
  def type, do: :string

  def cast(tuple) when is_tuple(tuple), do: tuple
  def cast(_), do: :error

  def load(inet=%Postgrex.INET{address: tuple}), do: {:ok, tuple}

  def dump(tuple) when is_tuple(tuple), do: {:ok, %Postgrex.INET{address: tuple}}
  def dump(_), do: :error
end
