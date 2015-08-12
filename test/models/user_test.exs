defmodule News.UserTest do
  use News.ModelCase

  alias News.User

  @valid_attrs %{banned: true, created_at: %{day: 17, hour: 14, min: 0, month: 4, year: 2010}, email: "some content", hash: "some content", username: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
