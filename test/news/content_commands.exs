defmodule News.ContentCommandsTest do
  use ExUnit.Case, async: true

  test "extract/1" do
    import News.Content.Commands, only: [extract: 1]
    assert extract("kikoo") == {"kikoo", []}
    assert extract("//lol mdr\nkikoo") == {"kikoo", ["lol mdr"]}
    assert extract("kikoo\n//lol mdr") == {"kikoo", []}
  end
end
