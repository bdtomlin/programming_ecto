defmodule RepoFunctions do
  # Wherever you want to use this, just import it
  # import RepoFunctions

  defmacro lower(arg) do
    quote do: fragment("lower(?)", unquote(arg))
  end
end
