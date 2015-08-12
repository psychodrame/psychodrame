defmodule News.WikiTest do
  use News.ModelCase

  alias News.Wiki

  @valid_attrs %{custom_path: "some content", path: "some content", tag: nil}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Wiki.changeset(%Wiki{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Wiki.changeset(%Wiki{}, @invalid_attrs)
    refute changeset.valid?
  end
end
