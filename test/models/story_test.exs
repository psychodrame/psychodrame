defmodule News.StoryTest do
  use News.ModelCase

  alias News.Story

  @valid_attrs %{content: "some content", link: "some content", title: "some content", type: "some content", user: nil}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Story.changeset(%Story{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Story.changeset(%Story{}, @invalid_attrs)
    refute changeset.valid?
  end
end
