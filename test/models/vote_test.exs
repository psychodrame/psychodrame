defmodule News.VoteTest do
  use News.ModelCase

  alias News.Vote

  @valid_attrs %{user: nil, votable_id: 42, votable_type: "some content", vote: true}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Vote.changeset(%Vote{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Vote.changeset(%Vote{}, @invalid_attrs)
    refute changeset.valid?
  end
end
