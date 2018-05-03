
defmodule Simpler.Mock.Server do
  require Logger
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, {})
  end

  def expect_call(pid, message) do
    GenServer.call(pid, {:__expect_call__, message})
  end

  def verify({_mock_module, pid}) do
    import ExUnit.Assertions
    case GenServer.call(pid, {:__verify__}) do
      [] -> :ok
      msgs ->
        non_any = Enum.filter(msgs, fn({_call, _args, opts}) ->
          opts[:times] != :any
        end)
        if length(non_any) > 0 do
          flunk("Expected all calls to be seen, but still have some expectations left:\n\n#{inspect msgs}\n")
        end
    end
  end

  # Server side

  def init(_args) do
    {:ok, []}
  end

  def handle_call({:__expect_call__, message}, _from, state) do
    {:reply, :ok, state ++ [message]}
  end

  def handle_call({:__verify__}, _from, state) do
    {:reply, state, state}
  end

  # Stuff being sent by the generated code

  def handle_call({:__forward__, func, args}, _from, state) do
    index = find_match(state, func, args)
    if index == nil do
      raise "No matching expectation found for #{inspect func}(#{inspect args})"
    else
      {_f, _a, options} = Enum.at(state, index)
      reply = options[:reply]
      times = options[:times] || 1
      times_left = if times == :any, do: :any, else: times - 1
      rest = if times_left == 0 do
        List.delete_at(state, index)
      else
        # Write back the times left, now decremented
        List.update_at(state, index, fn({func, args, options}) ->
          {func, args, Keyword.put(options, :times, times_left)}
        end)
      end
      {:reply, reply, rest}
    end
  end

  # Find the index of the matching expectation, or nil
  # TODO when multiple expectations match on function. Probably recurse a bit
  defp find_match(expectations, func, args) do
    match_on_func_only = Enum.find_index(expectations, fn({f, _a, _r}) -> func == f end)
    case match_on_func_only do
      nil -> nil
      index ->
        {_f, expected_args, _r} = Enum.at(expectations, index)
        if match_args(expected_args, args) do
          index
        else
          nil
        end
    end
  end

  defp match_args([], [_stuff]), do: false
  defp match_args([_stuff], []), do: false
  defp match_args([], []), do: true
  defp match_args([ea | expected_args], [a | args]) do
    match_arg(ea, a) && match_args(expected_args, args)
  end
  # Special case - the expectation has a "variable"
  defp match_arg({_varname, _line, _stuff}, _), do: true
  defp match_arg(a, a), do: true
  defp match_arg(_, _), do: false
end
