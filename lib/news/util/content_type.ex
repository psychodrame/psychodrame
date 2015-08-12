defmodule News.Util.ContentType do
  require Logger

  @doc "get a type from a mime and/or a body. If no mime given `:magic` will try to find it from reading `body`"
  @spec get_type(String.t | nil, binary | nil) :: String.t
  def get_type(mime, body), do: mime_type_to_type extract_mime(mime, body)

  @types %{}
  @fallback_type nil
  defp mime_type_to_type("image"<>_), do: "image"
  defp mime_type_to_type("audio"<>_), do: "audio"
  defp mime_type_to_type("video"<>_), do: "video"
  defp mime_type_to_type("application/x-pdf"), do: "pdf"
  defp mime_type_to_type("application/pdf"), do: "pdf"
  defp mime_type_to_type(type), do: @types[type] || @fallback_type

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
