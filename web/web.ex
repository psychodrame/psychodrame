defmodule News.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use News.Web, :controller
      use News.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Model
      alias News.Repo
      alias __MODULE__
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      require Logger

      # Alias the data repository and import query/model functions
      alias News.Repo
      import Ecto.Model
      import Ecto.Query, only: [from: 2]
      alias News.User

      # Import URL helpers from the router
      import News.Router.Helpers
      import News.I18n.Helper
      import News.Session, only: [current_user: 1, logged_in?: 1]

      def error_not_found(conn) do
        conn
          |> put_status(:not_found)
          |> render(News.ErrorView, "404.html")
      end

    end
  end

  def base_view do
    quote do
      use Phoenix.View, root: "web/templates"
      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]
      # Import URL helpers from the router
      import News.Router.Helpers
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      # News: sessions utilities
      import News.Session, only: [current_user: 1, logged_in?: 1]
      # pluralize/1, singularize/1, inflect/1, ...
      import Inflex
      # t/3
      import News.I18n.Helper
    end
  end

  def view do
    quote do
      use News.Web, :base_view

      import News.HelperView, only: [format_date: 1, user_link: 1, external_link: 3,
                                      app_env: 1, app_env: 2, ui_settings: 1]
      import News.FlagView, only: [flags_for: 1, flags_for: 2, flags_class_for: 1, flags_class_for: 2]

      def markdown(text) do
        raw Cmark.to_html(text)
      end

    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      # Alias the data repository and import query/model functions
      alias News.Repo
      import Ecto.Model
      import Ecto.Query, only: [from: 2]

    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
