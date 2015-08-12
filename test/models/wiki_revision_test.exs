defmodule News.WikiRevisionTest do
  use News.ModelCase

  alias News.WikiRevision

  @valid_attrs %{content: "some content", title: "some content", wiki: nil}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = WikiRevision.changeset(%WikiRevision{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = WikiRevision.changeset(%WikiRevision{}, @invalid_attrs)
    refute changeset.valid?
  end
end
