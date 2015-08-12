defmodule News.Content.Commands do
  @doc """
  # Content Commands!

  Commands are added (one per line) on the begining of a comment. They start by a double slash sign `//`.

  ## Moderation commands:

  * `//title` - change title
  * `//untag` - remove tag
  * `//kill`  - kill comment
  * `//pin, //unpin`  - pinning

  """
  alias __MODULE__

  def commands, do: Enum.reduce(News.get_env(:commands), %{}, fn(mod, acc) ->
    Enum.reduce(mod.commands, acc, fn(command, acc) -> Map.put(acc, command, mod) end)
  end)

  defmodule Behaviour do
    use Elixir.Behaviour
    @doc "changeset(changeset, context, command, args)"
    defcallback commands() :: [String.t]
    defcallback changeset(Ecto.Changeset.t, Map.t, String.t, List.t) :: Ecto.Changeset.t
    defcallback after_save(Ecto.Changeset.t, Map.t, String.t, List.t) :: Ecto.Changeset.t
    defcallback finalize(Ecto.Model.t, Map.t, String.t, List.t) :: Ecto.Model.t
  end

  @doc "Returns the text stripped of commands, and the commands"
  @spec extract(String.t) :: {String.t, [String.t, ...]}
  def extract(text) do
    lines = String.split(text, "\n")
    {stripped_text, commands} = extract(lines, [], [])
    text = stripped_text
      |> List.flatten
      |> Enum.join("\n")
      |> String.strip
    {text, commands}
  end

  defp extract(["//"<>line|lines], stripped_text, commands) do
    command_and_args = line
      |> String.split(" ", parts: 2)
      |> Enum.map(fn(string) -> String.strip(string) end)

    extract(lines, stripped_text, [command_and_args|commands])
  end
  defp extract(remaining_text, stripped_text, commands) do
    {[remaining_text|stripped_text], commands}
  end

  defmodule Pipeline do
    @moduledoc "Behaviour implementation of News.Content.Pipeline for News.Content.Commands"
    alias News.Content.Commands
    @behaviour News.ContentPipeline.Behaviour

    def changeset(changeset, context) do
      {text, commands} = Commands.extract(context.value)
      changeset = validate_commands(commands, context, changeset)
      if changeset.valid? do
        commands = commands
          |> Enum.with_index
          |> Enum.map(fn({[command | args], index}) ->
              {Integer.to_string(index), %{"command" => command, "args" => args}}
            end)
          |> Enum.into(Map.new)
        changeset
          |> Ecto.Changeset.put_change(:commands, commands)
          |> Ecto.Changeset.put_change(context.field, text)
      else changeset end
    end

    def after_save(changeset, context) do
      commands = Ecto.Changeset.get_field(changeset, :commands)
      Enum.reduce(commands, changeset, fn({_, %{"command" => command, "args" => args}}, changeset) ->
        Commands.commands[command].after_save(changeset, context, command, args)
      end)
    end

    def finalize(model, context) do
      Enum.reduce(model.commands, model, fn({_, %{"command" => command, "args" => args}}, model) ->
        Commands.commands[command].finalize(model, context, command, args)
      end)
    end

    defp validate_commands([[command|args]|commands], context, changeset) do
      if Commands.commands[command] do
        changeset = Commands.commands[command].validate(changeset, context, command, args)
        validate_commands(commands, context, changeset)
      else
        Ecto.Changeset.add_error(changeset, context.field, News.td("commands.invalid", [command: command]))
      end
    end

    defp validate_commands([], context, changeset), do: changeset
  end

end
