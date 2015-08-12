defmodule News.I18n do
  use Linguist.Vocabulary

  locale "en", Path.join([__DIR__, "i18n", "en.exs"])
  locale "fr", Path.join([__DIR__, "i18n", "fr.exs"])

  defmodule Helper do
    @moduledoc "same as I18n.t/3 but a `Plug.Conn` as the first argument."
    def t(conn=%Plug.Conn{}, path, bindings \\ []) do
      News.I18n.t!(conn.assigns[:lang], path, bindings)
    end
    def td(path, bindings \\ []) do
      News.I18n.t!(Application.get_env(:news, :lang, "en"), path, bindings)
    end
  end
end
