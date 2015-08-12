defmodule News.FlagTest do
  use News.ModelCase

  alias News.Flag

  @valid_attrs %{class: "some content", description: "some content", link: "some content", name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Flag.changeset(%Flag{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Flag.changeset(%Flag{}, @invalid_attrs)
    refute changeset.valid?
  end
end
