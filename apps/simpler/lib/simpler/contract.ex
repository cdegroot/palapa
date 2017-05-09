defmodule Simpler.Contract do
  @moduledoc """
  Very basic Design-by-Contract support.
  """

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [def: 2]
      import Simpler.Contract, only: [def: 2, precondition: 1, postcondition: 1]
    end
  end

  require Logger

  defmacro def(name_and_args, body) do
    {name, line_info, args} = name_and_args
    key = {name, length(args)}
    current_key = Module.get_attribute(__CALLER__.module, :__contracted_fn__) || key
    if key != current_key do
      Module.delete_attribute(__CALLER__.module, :__pre__)
      Module.delete_attribute(__CALLER__.module, :__post__)
      Module.delete_attribute(__CALLER__.module, :__contracted_fn__)
    else
      Module.put_attribute(__CALLER__.module, :__contracted_fn__, key)
    end
    do_block = case body[:do] do
      {:__block__, [], _stmts} = block -> block
      block -> {:__block__, [], [block]}
    end
    # TODO this uses internal AST knowledge.
    pre_blocks  = (Module.get_attribute(__CALLER__.module, :__pre__)  || [true])
    |> assertify
    |> simplify
    post_blocks = (Module.get_attribute(__CALLER__.module, :__post__) || [true])
    |> assertify
    |> simplify
    quote do
      Kernel.def unquote(name)(unquote_splicing(args)) do
        unquote(pre_blocks)
        var!(result) = unquote(do_block)
        unquote(post_blocks)
        var!(result)
      end
    end
  end

  defmacro precondition(stuff) do
    push_attr(__CALLER__.module, :__pre__, stuff)
  end

  defmacro postcondition(stuff) do
    push_attr(__CALLER__.module, :__post__, stuff)
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
  defp assertify(statements) do
    lines = do_assertify(statements)
    {:__block__, [], lines}
  end
  defp do_assertify([stmt | rest]) do
    [assertify_one(stmt) | do_assertify(rest)]
  end
  defp do_assertify([]) do
    []
  end
  defp do_assertify(x) do
    [assertify_one(x)]
  end
  defp assertify_one(x) do
    quote do: assert unquote(x)
  end

  # Simplify assertions - multiple assertions in a block are
  # flattened to a single statement, `assert(true)` is eliminated
  defp simplify([stmt | rest]) do
    [simplify(stmt) | simplify(rest)]
  end
  defp simplify([]) do
    []
  end
  defp simplify({:__block__, _lines, [single_stmt]}) do
    simplify(single_stmt)
  end
  defp simplify({:assert, [], [true]}) do
    []
  end
  defp simplify(x) do
    x
  end
end
