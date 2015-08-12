defmodule News.Content.Markdown do

  def to_html(string) do
    string
      |> Cmark.to_html
  end

  defmodule Pipeline do
    @behaviour News.ContentPipeline.Behaviour
    alias News.Content.Markdown

    def changeset(changeset, context) do
      html_field_name = String.to_atom(Atom.to_string(context.field)<>"_html")
      markdown = Ecto.Changeset.get_field(changeset, context.field)
      html = Markdown.to_html(markdown)
      if html do
        Ecto.Changeset.put_change(changeset, html_field_name, html)
      else
        Ecto.Changeset.add_error(changeset, context.field, News.td("errors.invalid_markdown"))
      end
    end

    def after_save(changeset, _), do: changeset
    def finalize(model, _), do: model
  end

end
