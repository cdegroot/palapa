defmodule Simpler.Contract do
  @moduledoc """
  Very basic Design-by-Contract support.

  ```
  precondition op_one > op_two
  postcondition result > 0
  def subtract(op_one, op_two) do
    op_one - op_two
  end
  ```

  You can have any number of pre- and postconditions, and they will apply to
  any head of the function that follows. Postconditions can use the variable
  `result` which will hold the result of the function (so, err, yeah - the
  `Simpler.Contract.def` macro is not hygienic - don't use `result` in your
  own code. Although it usually should not conflict as this result is only
  assigned and used _after_ the last line of your method body's code).
  """

  @pre  :__contract__pre__
  @post :__contract__post__
  @fun  :__contract__fn__

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [def: 2]
      import Simpler.Contract, only: [def: 2, precondition: 1, postcondition: 1]
      Module.register_attribute(__MODULE__, :pre, accumulate: true)
      Module.register_attribute(__MODULE__, :post, accumulate: true)
    end
  end

  require Logger

  @doc """
  Override of def that will run current contract definitions.
  """
  defmacro def(name_and_args, body) do
    {name, _, args} = name_and_args
    key = {name, length(args)}
    caller_module = __CALLER__.module
    current_key = Module.get_attribute(caller_module, @fun) || key
    if key != current_key do
      Module.delete_attribute(caller_module, @pre)
      Module.delete_attribute(caller_module, @pre)
      Module.delete_attribute(caller_module, @fun)
    else
      Module.put_attribute(caller_module, @fun, key)
    end
    pre_blocks  = (Module.get_attribute(caller_module, @pre)  || [true])
    |> assertify
    |> simplify
    post_blocks = (Module.get_attribute(caller_module, @post) || [true])
    |> assertify
    |> simplify
    quote do
      Kernel.def unquote(name)(unquote_splicing(args)) do
        unquote_splicing(pre_blocks)
        var!(result) = unquote(body[:do])
        unquote_splicing(post_blocks)
        var!(result)
      end
    end
  end

  @doc """
  Define a precondition. Argument names should be availablable in any
  function head's arguments. If the precondition doesn't hold, raise
  an error.
  """
  defmacro precondition(stuff) do
    push_attr(__CALLER__.module, @pre, stuff)
  end

  @doc """
  Define a postcondition. A special variable `result` holds the result
  of the function. If the postcondition doesn't hold, raise an error.
  """
  defmacro postcondition(stuff) do
    push_attr(__CALLER__.module, @post, stuff)
  end

  defp push_attr(env, key, stuff) do
    cur = Module.get_attribute(env, key)
    if cur == nil do
      Module.put_attribute(env, key, [stuff])
    else
      Module.put_attribute(env, key, cur ++ stuff)
    end
  end

  # Given a list of statements, make a list of asserts
  defp assertify([stmt | rest]) do
    [assertify_one(stmt) | assertify(rest)]
  end
  defp assertify([]) do
    []
  end
  defp assertify(x) do
    [assertify_one(x)]
  end
  defp assertify_one(x) do
    quote do: assert unquote(x)
  end

  # Simplify assertions by eliminating any `assert(true)` which
  # would trigger compiler warnings.
  defp simplify([stmt | rest]) do
    [simplify(stmt) | simplify(rest)]
  end
  defp simplify({:assert, [], [true]}) do
    []
  end
  defp simplify(x) do
    x
  end
end
