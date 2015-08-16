defmodule News.Content.Link do
  @moduledoc """
  Validates and stores link information
  """

  # TODO: Limit -request size-(ok) / request time
  # TODO: Make it run in a separate process

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
      link = News.Link.process(get_field(changeset, context.field))
      if link.valid do
        attrs = get_field(changeset, :attrs)
          |> Map.put("http_status", link.status)
          |> Map.put("domain", link.domain)
          |> Map.put("sha", link.sha)
          |> Map.put("content_type", link.content_type)
          |> Map.put("type", link.type)
          |> Map.put("thumbnail_url", link.thumbnail_url)
          |> Map.put("preview_url", link.preview_url)
          |> Map.put("preview_html", link.preview_html)
        News.Util.TempFile.release
        put_change(changeset, :attrs, attrs)
      else
        reason = case link.error do
          {:status, status} -> "link returned http status #{status}"
          {:fetch_error, error} -> "link crawl failed: #{inspect error}"
          error -> "link processing failed: #{inspect error}"
        end
        add_error(changeset, context.field, reason)
      end
    end

    def after_save(changeset, _), do: changeset

    def finalize(model, _) do
      model
    end
  end

end
