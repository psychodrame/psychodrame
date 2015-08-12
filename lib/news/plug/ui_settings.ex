defmodule News.Plug.UISettings do
  import Plug.Conn
  import Phoenix.Controller
  import News.I18n.Helper

  defstruct external_new_tabs: nil, list_links_story: nil, show_thumbnails: nil

  def init(state), do: state

  def call(conn, state) do
    settings = if u = conn.assigns[:current_user] do
      %__MODULE__{
        external_new_tabs: u.s_external_new_tabs,
        list_links_story: u.s_list_links_story,
        show_thumbnails: u.s_show_thumbnails,
      }
    else
      struct(__MODULE__, News.get_env(:ui_default_settings))
    end
    assign(conn, :ui_settings, settings)
  end
end
