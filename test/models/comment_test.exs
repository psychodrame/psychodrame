defmodule News.CommentTest do
  use News.ModelCase

  alias News.Comment

  @valid_attrs %{comment: nil, content: "some content", submission: nil, user: nil}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Comment.changeset(%Comment{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Comment.changeset(%Comment{}, @invalid_attrs)
    refute changeset.valid?
  end
end
