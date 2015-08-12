defmodule News.TaggingTest do
  use News.ModelCase

  alias News.Tagging

  @valid_attrs %{story: nil, tag: nil, user: nil}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Tagging.changeset(%Tagging{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Tagging.changeset(%Tagging{}, @invalid_attrs)
    refute changeset.valid?
  end
end
