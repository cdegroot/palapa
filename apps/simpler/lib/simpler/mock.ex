defmodule Simpler.Mock do
  @moduledoc """
  A generic Mock module which can receive expectations and later verify them.
  """
  # Currently very basic, but functional.
  # TODO now we're in full mocking territory, :once, :twice, :any, times?
  # TODO save unexpected calls and fail that on verify (for now, we immediately crash)

  require Logger

  defmacro __using__(_opts) do
    quote do
      # Make people write "Mock.foo" for clarity.
      require Simpler.Mock
      alias Simpler.Mock
    end
  end

  @doc """
  Generate a mock with expectations.

  Returns {:ok, {mock_module, mock_pid}}
  """
  defmacro with_expectations(opts) do
    # TODO mucho cleanups, splitting
    # TODO try to expand variables - if they resolve to a value, use these
    caller_mod = __CALLER__.module
    {caller_fun, _arity} = __CALLER__.function
    random_module_name = Integer.to_string(:rand.uniform(100000000000))
    mock_module = Module.concat([caller_mod, caller_fun, random_module_name])
    result = statements(opts[:do])
    |> Enum.map(fn({:expect_call, _, expectation}) ->
      {msg, args, reply} = call_to_message(expectation)
      args = args || []
      forwarder = Simpler.Mock.Generator.make_forwarder({msg, length(args)}, quote do: @pid)
      expectation = quote do
        Simpler.Mock.Server.expect_call(pid, {unquote(msg), unquote(args), unquote(reply)})
      end
      {expectation, forwarder}
    end)
    expectations = Enum.map(result, fn({e, _f}) -> e end)
    forwarders = Enum.map(result, fn({_e, f}) -> f end)
    forwarders = forwarders |> Macro.escape
    quote do
      {:ok, pid} = Simpler.Mock.Server.start_link()
      putattr = quote do: Module.put_attribute(__MODULE__, :pid, unquote(pid))
      forwarders = [putattr | unquote(forwarders)]
      Module.create(unquote(mock_module), forwarders, Macro.Env.location(__ENV__))
      unquote_splicing(expectations)
      {:ok, {unquote(mock_module), pid}}
    end
  end

  @doc """
  Verify expectations
  """
  def verify(pid), do: Simpler.Mock.Server.verify(pid)

  # Private stuff

  defp statements({:__block__, _, statements}), do: statements
  defp statements(statement), do: [statement]

  defp call_to_message([{message, _, args}]) do
    {message, protect_vars_in_args(args), :ok}
  end
  defp call_to_message([{message, _, args}, [reply: canned_reply]]) do
    {message, protect_vars_in_args(args), canned_reply}
  end
  # Bad name. In any case, when we use a variable with an underscore, that
  # signifies a "don't care" value. We splice it back not as a variable, but
  # as the variable's AST so the matching will skip it.
  defp protect_vars_in_args(args) do
    Enum.map(args, &protect_vars_in_arg/1)
  end
  defp protect_vars_in_arg({var, _line, _stuff} = arg) do
    if String.starts_with?(Atom.to_string(var), "_") do
      Macro.escape(arg)
    else
      arg
    end
  end
  defp protect_vars_in_arg(arg), do: arg
end
