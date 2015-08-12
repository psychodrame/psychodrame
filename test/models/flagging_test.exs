defmodule News.FlaggingTest do
  use News.ModelCase

  alias News.Flagging

  @valid_attrs %{flagged_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Flagging.changeset(%Flagging{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Flagging.changeset(%Flagging{}, @invalid_attrs)
    refute changeset.valid?
  end
end
