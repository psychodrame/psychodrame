defmodule News.FlagView do
  use News.Web, :base_view

  def flags_for(model, type \\ :small) do
    render __MODULE__, "flags.html", %{target: model, type: type}
  end

  def flags_class_for(model, prefix \\ "flagged") do
    render __MODULE__, "classes.html", %{target: model, prefix: prefix}
  end

  def render("flags.html", %{target: target, type: type}) do
    target = News.Repo.preload(target, :flags)
    if !Enum.empty?(target.flags) do
      flags = Enum.map(Enum.uniq(target.flags), fn(flag) ->
        flag_html = "<em class='flag flag-#{flag.name} #{flag.class}' title='#{flag.comment}'>#{flag.text}</em>"
        if type == :expand do
          expand = "&nbsp;<span class='flag-expand flag-expand-#{flag.name}' title='#{flag.name}'>#{flag.comment}</span><br />"
          [flag_html, expand]
        else flag_html end
      end)
        |> List.flatten |> Enum.join("")
      raw "<span class='flags'>" <> flags <> "</span>"
    else
      raw "<!--unflagged-->"
    end
  end

  def render("classes.html", %{target: target, prefix: prefix}) do
    target = News.Repo.preload(target, :flags)
    unless Enum.empty?(target.flags) do
      Enum.map(Enum.uniq(target.flags), fn(flag) -> prefix <> "-" <> flag.name end)
        |> Enum.join(" ")
    else "" end
  end

end
