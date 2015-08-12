defmodule News.WikiControllerTest do
  use News.ConnCase

  alias News.Wiki
  @valid_attrs %{custom_path: "some content", path: "some content", tag: nil}
  @invalid_attrs %{}

  setup do
    conn = conn()
    {:ok, conn: conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, wiki_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing wikis"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, wiki_path(conn, :new)
    assert html_response(conn, 200) =~ "New wiki"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, wiki_path(conn, :create), wiki: @valid_attrs
    assert redirected_to(conn) == wiki_path(conn, :index)
    assert Repo.get_by(Wiki, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, wiki_path(conn, :create), wiki: @invalid_attrs
    assert html_response(conn, 200) =~ "New wiki"
  end

  test "shows chosen resource", %{conn: conn} do
    wiki = Repo.insert! %Wiki{}
    conn = get conn, wiki_path(conn, :show, wiki)
    assert html_response(conn, 200) =~ "Show wiki"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_raise Ecto.NoResultsError, fn ->
      get conn, wiki_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    wiki = Repo.insert! %Wiki{}
    conn = get conn, wiki_path(conn, :edit, wiki)
    assert html_response(conn, 200) =~ "Edit wiki"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    wiki = Repo.insert! %Wiki{}
    conn = put conn, wiki_path(conn, :update, wiki), wiki: @valid_attrs
    assert redirected_to(conn) == wiki_path(conn, :index)
    assert Repo.get_by(Wiki, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    wiki = Repo.insert! %Wiki{}
    conn = put conn, wiki_path(conn, :update, wiki), wiki: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit wiki"
  end

  test "deletes chosen resource", %{conn: conn} do
    wiki = Repo.insert! %Wiki{}
    conn = delete conn, wiki_path(conn, :delete, wiki)
    assert redirected_to(conn) == wiki_path(conn, :index)
    refute Repo.get(Wiki, wiki.id)
  end
end
