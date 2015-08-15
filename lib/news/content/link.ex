defmodule News.Content.Link do
  @moduledoc """
  Validates and extracts link information:
  * validate it is not a dead link
  * stores content-type
  * tbd
  """

  # TODO: Do a HEAD before the get
  # TODO: Limit request size / request time
  # TODO: Make it run in a separate process
  # TODO: Cache results for later user (if used without a model, e.g. live validation)

  @allowed_schemes ~w(http https)

  def allowed_schemes, do: @allowed_schemes

  @spec validate_link_syntax(String.t) :: {:ok, String.t} | {:error, String.t}
  def validate_link_syntax(link) when is_binary(link), do: validate_link_syntax(link, URI.parse(link))
  def validate_link_syntax(_), do: {:error, "is required"}
  defp validate_link_syntax(link, %{scheme: s, host: h}) when s in @allowed_schemes and not is_nil(h), do: {:ok, link}
  defp validate_link_syntax(_, nil), do: {:error, "is required"}
  defp validate_link_syntax(_, %{scheme: s}) when not s in @allowed_schemes, do: {:error, "scheme #{s} not allowed"}
  defp validate_link_syntax(_, _), do: {:error, "is invalid"}

  defmodule Pipeline do
    @behaviour News.ContentPipeline.Behaviour
    import Ecto.Changeset
    require Logger

    def changeset(changeset, context) do
      case News.Content.Link.validate_link_syntax(context.value) do
        {:ok, _} -> validate_fetch(changeset, context)
        {:error, err} -> add_error(changeset, context.field, err)
      end
    end

    def validate_fetch(changeset, context) do
      meta = News.Link.process(get_field(changeset, context.field))
      if meta.valid do
        preview_url = if context.value != meta.url, do: meta.url, else: nil
        attrs = get_field(changeset, :attrs)
          |> Map.put("http_status", meta.status)
          |> Map.put("domain", meta.domain)
          |> Map.put("sha", meta.sha)
          |> Map.put("content_type", meta.content_type)
          |> Map.put("type", meta.type)
          |> Map.put("thumbnail_url", meta.thumbnail_url)
          |> Map.put("preview_url", preview_url)
          |> Map.put("preview_html", meta.preview)
        News.Util.TempFile.release
        put_change(changeset, :attrs, attrs)
      else
        case meta.error do
          {:status, s} -> add_error(changeset, context.field, "link crawl returned status #{s}")
          {:fetch_error, err} -> add_error(changeset, context.field, "link crawl failed: #{inspect err}")
        end
      end
    end

    def after_save(changeset, _), do: changeset

    def finalize(model, context) do
      model
    end
  end

end
