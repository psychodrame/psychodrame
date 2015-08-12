defmodule News.CacheController do
  use News.Web, :controller
  alias News.Story

  @cache_control %{
    default: "public, max-age=1209600",
    error:   "public, must-revalidate, max-age=7200",
    low:     "public, must-revalidate, max-age=30",
  }
  @low_cache_sha [
    "f0e377c20a27c8d9bb6ec16bdfb5d2e21b38c9e6", # bitpixels coming soon
  ]

  def story(conn, params=%{"hash" => hash, "slug" => slug}) do
    extension = case params["ext"] do
      ["cached."<>rest] -> "."<>rest
      _ -> ""
    end
    case get_story(hash, slug) do
      {:ok, story} ->
        if story.type == "link" and story.attrs["type"] == "image" do
          case proxy_request(story.attrs["preview_url"] || story.link) do
            {:ok, content_type, body} ->
              conn
                |> set_cache(News.HTTP.body_sha(body))
                |> put_resp_content_type(content_type)
                |> send_resp(200, body)
            {:error, error} ->
              conn
                |> set_cache(:error)
                |> redirect(to: story.link)
          end
        else
          conn
            |> set_cache(:default)
            |> redirect(to: story.link)
        end
      {:redirect, path} ->
        conn
          |> set_cache(:default)
          |> redirect(to: path<>"cached"<>extension)
      _ -> error_not_found(conn)
    end
  end

  def story_thumb(conn, params=%{"hash" => hash, "slug" => slug}) do
    extension = case params["ext"] do
      ["thumb."<>rest] -> "."<>rest
      _ -> ""
    end
    case get_story(hash, slug) do
      {:ok, story} ->
        case proxy_request(Story.thumbnail_url(story)) do
          {:ok, content_type, body} ->
            conn
              |> set_cache(News.HTTP.body_sha(body))
              |> put_resp_content_type(content_type)
              |> send_resp(200, body)
          {:error, error} ->
            conn
              |> set_cache(:error)
              |> redirect(to: story.link)
        end
      {:redirect, path} ->
        conn
          |> set_cache(:default)
          |> redirect(to: path<>"thumb"<>extension)
      _ -> error_not_found(conn)
    end
  end

  def story_html(conn, params=%{"hash" => hash, "slug" => slug}) do
    case get_story(hash, slug) do
      {:ok, story} ->
        conn
          |> put_layout(false)
          |> set_cache(:default)
          |> render("iframe_preview.html", html: (story.attrs["preview_html"] || story.content_html))
      {:redirect, path} ->
        conn
          |> set_cache(:default)
          |> redirect(to: path<>"preview_html")
      _ -> error_not_found(conn)
    end
  end


  defp get_story(hash, slug) do
    get_story_from_repo(Story.decode_id(hash), slug)
  end
  defp get_story_from_repo(id, slug) when is_integer(id), do: get_story_and_slug(Repo.get(Story, id), slug)
  defp get_story_from_repo(_, _), do: {:error, :hash}
  defp get_story_and_slug(story=%Story{}, slug), do: validate_story_slug(story, Story.slug(story) == slug)
  defp get_story_and_slug(_, _), do: {:error, :not_found}
  defp validate_story_slug(story, true), do: {:ok, story}
  defp validate_story_slug(story, false), do: {:redirect, Story.url(story)}

  defp proxy_request(link) do
    headers = [{"user-agent", News.user_agent(:cache)}]
    options = [:insecure, {:follow_redirect, true}]
    case :hackney.request(:get, link, headers, "", options) do
      {:ok, 200, headers, client} ->
        headers = Enum.into(headers, Map.new)
        {:ok, body} = :hackney.body(client)
        {:ok, headers["Content-Type"], body}
      {:ok, status, _, _} ->
        Logger.warn "CacheController proxy request failed, status #{status}, link: #{link}"
        {:error, :bad_status}
      {:error, error} ->
        Logger.warn "CacheController proxy request failed, error #{inspect error}, link: #{link}"
        {:error, error}
    end
  end

  defp set_cache(conn, key) when is_atom(key) do
    put_resp_header(conn, "cache-control", @cache_control[key])
  end

  defp set_cache(conn, sha) when is_binary(sha) do
    key = if Enum.member?(@low_cache_sha, sha), do: :low, else: :default
    set_cache(conn, key)
  end

end
