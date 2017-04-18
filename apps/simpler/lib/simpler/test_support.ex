defmodule Simpler.TestSupport do
  @moduledoc """
  Code to make code simpler to test
  """

  @doc """
  A def that's a defp except when Mix.env is set and equal to `:test`
  """
  defmacro deft(call, expr \\ nil) do
    if Mix.env == :test do
      quote do: def(unquote(call), unquote(expr))
    end
  end
end
