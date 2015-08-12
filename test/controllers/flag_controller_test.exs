defmodule News.FlagControllerTest do
  use News.ConnCase

  alias News.Flag
  @valid_attrs %{class: "some content", comment: "some content", hidden: true, link: "some content", name: "some content", text: "some content"}
  @invalid_attrs %{}

  setup do
    conn = conn()
    {:ok, conn: conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, flag_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing flags"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, flag_path(conn, :new)
    assert html_response(conn, 200) =~ "New flag"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, flag_path(conn, :create), flag: @valid_attrs
    assert redirected_to(conn) == flag_path(conn, :index)
    assert Repo.get_by(Flag, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, flag_path(conn, :create), flag: @invalid_attrs
    assert html_response(conn, 200) =~ "New flag"
  end

  test "shows chosen resource", %{conn: conn} do
    flag = Repo.insert! %Flag{}
    conn = get conn, flag_path(conn, :show, flag)
    assert html_response(conn, 200) =~ "Show flag"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_raise Ecto.NoResultsError, fn ->
      get conn, flag_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    flag = Repo.insert! %Flag{}
    conn = get conn, flag_path(conn, :edit, flag)
    assert html_response(conn, 200) =~ "Edit flag"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    flag = Repo.insert! %Flag{}
    conn = put conn, flag_path(conn, :update, flag), flag: @valid_attrs
    assert redirected_to(conn) == flag_path(conn, :index)
    assert Repo.get_by(Flag, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    flag = Repo.insert! %Flag{}
    conn = put conn, flag_path(conn, :update, flag), flag: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit flag"
  end

  test "deletes chosen resource", %{conn: conn} do
    flag = Repo.insert! %Flag{}
    conn = delete conn, flag_path(conn, :delete, flag)
    assert redirected_to(conn) == flag_path(conn, :index)
    refute Repo.get(Flag, flag.id)
  end
end
