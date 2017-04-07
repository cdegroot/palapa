
defmodule Simpler.Mock.Generator do
  @moduledoc """
  Mock code generation utilities
  """
  require Logger

  def make_forwarder({func, arity}, mock_pid) do
    args = make_arg_list(arity)
    quote do
      def unquote(func)(unquote_splicing(args)) do
        GenServer.call(unquote(mock_pid), {:__forward__, unquote(func), unquote(args)})
      end
    end
  end

  defp make_arg_list(arity) do
    # Make an arg list one too long, strip the first element,
    # then convert to atoms and then to variables.
    (tl for i <- 0..arity, do: "arg#{i}")
    |> Enum.map(&String.to_atom/1)
    |> Enum.map(&(Macro.var(&1, __MODULE__)))
  end
end
