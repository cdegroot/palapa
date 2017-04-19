defmodule Simpler.Mock do
  @moduledoc """
  A generic Mock module which can receive expectations and later
  verify them. Verification is optional. This module is a work in
  progress driven by real-world testing needs, rather than by grand
  ideas. As such, it is fairly minimal.

  Mocks are supported in the code using it by making indirect calls through
  references. So the production code holds a reference as a `{mod, pid}` tuple
  and calls code like:

  ```
  mod.do_something(pid, arg1, ...)
  ```

  By making the module variable in the production code, it becomes clean and simple
  to swap references between "real" and "mock" code on a case-by-case basis. In fact,
  it is simple enough to e.g. write a mock `GenServer` and use that in a test - this
  code is mostly syntactic sugar on top of it.

  A quick example of how to create a mock:

  ```
  use Simpler.Mock
  {:ok, mock_dependency} = Mock.with_expectations do
    expect_call some_call(_some_pid, "you", "me"), reply: :ok_by_me, times: :any
  end
  ```

  This creates a mock that expects `some_call` zero to any times, will always reply
  `:ok_by_me`, and should have the arguments `"you"` and `"me"`. The `_some_pid`
  argument starts with an underscore, which means it is ignored.

  `:reply` and `:times` are both optional. The default reply is `:ok` and the default
  times is one. Mocks can have zero or more expectations - whenever an expectation
  is matched, it's checked off the list, so when at the end of a run a call to

  ```
  Mock.verify(mock)
  ```

  is made, the call will succeed if all expectations have been seen.

  Internall, a mock is a `GenServer` in an on-the-fly-defined, randomly-named module.
  """

  require Logger

  defmacro __using__(_opts) do
    quote do
      # Make people write "Mock.foo" for clarity.
      require Simpler.Mock
      alias Simpler.Mock
    end
  end

  @doc """
  Generate a mock with expectations. Expectations are statements in the form

  ```
  expect_call function_name(arg1, arg2, ...argN), reply: reply, times: times
  ```

  Where `reply` and `times` are optional. Arguments can either be bound values or
  underscored placeholders - matching expectations with actual invocations will only
  take bound values into consideration, so underscored placeholders are effectively
  wildcards.

  Returns `{:ok, {mock_module, mock_pid}}`
  """
  defmacro with_expectations(opts) do
    # TODO mucho cleanups, splitting
    # TODO try to expand variables - if they resolve to a value, use these
    caller_mod = __CALLER__.module
    {caller_fun, _arity} = __CALLER__.function
    result = statements(opts[:do] || [])
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
      random_module_name = Integer.to_string(:rand.uniform(100000000000))
      mock_module = Module.concat([unquote(caller_mod), unquote(caller_fun), random_module_name])
      Module.create(mock_module, forwarders, Macro.Env.location(__ENV__))
      unquote_splicing(expectations)
      {:ok, {mock_module, pid}}
    end
  end

  @doc """
  Verify expectations. This will `flunk` the test if the expectations didn't match
  actual invocations.
  """
  def verify(pid), do: Simpler.Mock.Server.verify(pid)

  # Private stuff

  defp statements([]), do: []
  defp statements({:__block__, _, statements}), do: statements
  defp statements(statement), do: [statement]

  defp call_to_message([{message, _, args}]) do
    {message, protect_vars_in_args(args), [reply: :ok]}
  end
  defp call_to_message([{message, _, args}, options]) do
    {message, protect_vars_in_args(args), options}
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
