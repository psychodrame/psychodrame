defmodule News.Router do
  use News.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug News.Plug.CurrentUser
    plug News.Plug.Lang
    plug News.Plug.UISettings
  end

  pipeline :light do
    plug :accepts, ["html"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", News do
    pipe_through :browser # Use the default browser stack

    #get "/", PageController, :index
    get "/", StoryController, :frontpage, as: :root
    get "/latest", StoryController, :latest, as: :root
    resources "/stories", StoryController, except: [:index, :new, :show, :create]
    resources "/account", UserController, only: [:index, :create, :update, :delete]
    put "/account", UserController, :login, as: :login
    get "/account/logout", UserController, :logout, as: :logout
    post "/account/logout", UserController, :logout, as: :logout
    resources "/flags", FlagController
    get "/submit", StoryController, :new
    post "/submit", StoryController, :create
    get "/submit/:type", StoryController, :new, as: :submit
    get "/tags", TagController, :index, as: :tag
    get "/t/:name", TagController, :show, as: :tag
    get "/t/:tag/s/:hash/:slug", StoryController, :show, as: :story_tag # TODO

    # Submission
    get "/s/:hash", StoryController, :show
    get "/s/:hash/:slug", StoryController, :show, as: :show_story

    # Comments
    post "/comment", CommentController, :create, as: :comment
    get "/c/:comment_hash", CommentController, :show, as: :comment
    get "/c/:comment_hash/reply", CommentController, :new, as: :comment_reply
    post "/vote", VoteController, :create, as: :vote

    # Wiki
    resources "/t/:tag/wiki", WikiController, as: :tag_wiki
    resources "/p", WikiController, as: :site_wiki

    # User Profile
    get "/~*username", UserController, :show, as: :profile
  end

  scope "/s/:hash/:slug/cached*ext", News do
    pipe_through :light
    get "/", CacheController, :story, as: :cache
  end

  scope "/s/:hash/:slug/thumb*ext", News do
    pipe_through :light
    get "/", CacheController, :story_thumb, as: :cache
  end

  scope "/s/:hash/:slug/preview_html", News do
    pipe_through :light
    get "/", CacheController, :story_html, as: :cache
  end

end
