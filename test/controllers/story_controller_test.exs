defmodule News.StoryControllerTest do
  use News.ConnCase

  alias News.Story
  @valid_attrs %{content: "some content", link: "some content", title: "some content", type: "some content", user: nil}
  @invalid_attrs %{}

  setup do
    conn = conn()
    {:ok, conn: conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, story_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing stories"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, story_path(conn, :new)
    assert html_response(conn, 200) =~ "New story"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, story_path(conn, :create), story: @valid_attrs
    assert redirected_to(conn) == story_path(conn, :index)
    assert Repo.get_by(Story, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, story_path(conn, :create), story: @invalid_attrs
    assert html_response(conn, 200) =~ "New story"
  end

  test "shows chosen resource", %{conn: conn} do
    story = Repo.insert! %Story{}
    conn = get conn, story_path(conn, :show, story)
    assert html_response(conn, 200) =~ "Show story"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_raise Ecto.NoResultsError, fn ->
      get conn, story_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    story = Repo.insert! %Story{}
    conn = get conn, story_path(conn, :edit, story)
    assert html_response(conn, 200) =~ "Edit story"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    story = Repo.insert! %Story{}
    conn = put conn, story_path(conn, :update, story), story: @valid_attrs
    assert redirected_to(conn) == story_path(conn, :index)
    assert Repo.get_by(Story, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    story = Repo.insert! %Story{}
    conn = put conn, story_path(conn, :update, story), story: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit story"
  end

  test "deletes chosen resource", %{conn: conn} do
    story = Repo.insert! %Story{}
    conn = delete conn, story_path(conn, :delete, story)
    assert redirected_to(conn) == story_path(conn, :index)
    refute Repo.get(Story, story.id)
  end
end
