defmodule News.Util.ContentType do
  require Logger

  @type raw_content_type :: String.t
  @type content_type :: String.t
  @type type :: String.t

  @doc "get a type from a mime and/or a body. If no mime given `:magic` will try to find it from reading `body`"
  @spec get_type(raw_content_type | nil, binary | nil) :: {content_type, type}
  def get_type(mime, body), do: mime_type_to_type extract_mime(mime, body)

  @types %{}
  @fallback_type nil
  defp mime_type_to_type(mime="image"<>_), do: {mime, "image"}
  defp mime_type_to_type(mime="audio"<>_), do: {mime, "audio"}
  defp mime_type_to_type(mime="video"<>_), do: {mime, "video"}
  defp mime_type_to_type(mime="application/x-pdf"), do: {mime, "pdf"}
  defp mime_type_to_type(mime="application/pdf"), do: {mime, "pdf"}
  defp mime_type_to_type(mime), do: {mime, @types[mime] || @fallback_type}

  defp extract_mime(mime, _) when is_binary(mime), do: String.split(mime, ";") |> List.first
  defp extract_mime(_, body) do
    try do
      :magic.getMimeType(body)
    rescue
      _err ->
        Logger.error "ContentType magic rescue: #{inspect _err}"
        nil
    catch
      _err ->
        Logger.error "ContentType magic catch: #{inspect _err}"
        nil
    else
      v -> List.to_string(v)
    end
  end

end
