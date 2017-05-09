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
    Logger.error("Some def! #{inspect(name_and_args)}")
    {name, _, args} = name_and_args
    key = {name, length(args)}
    current_key = Module.get_attribute(__CALLER__.module, :__contracted_fn__) || key
    Logger.error("Key: #{inspect key}, current_key: #{inspect current_key}")
    if key != current_key do
      Logger.error("Wiping #{inspect key} not is #{inspect current_key}")
      Module.delete_attribute(__CALLER__.module, :__pre__)
      Module.delete_attribute(__CALLER__.module, :__post__)
      Module.delete_attribute(__CALLER__.module, :__contracted_fn__)
    else
      Module.put_attribute(__CALLER__.module, :__contracted_fn__, key)
    end
    do_block = body[:do]
    Logger.error("      do: #{inspect do_block}")
    pre_block = Module.get_attribute(__CALLER__.module, :__pre__) || [do: true]
    post_block = Module.get_attribute(__CALLER__.module, :__post__) || [do: true]
    Logger.error("     pre: #{inspect pre_block}")
    Logger.error("    post: #{inspect post_block}")
    quote do
      Kernel.def unquote(name)(unquote_splicing(args)) do
        assert unquote(pre_block[:do])
        # TODO cleanest method to grab the result?
        var!(result) = if true do
          unquote(do_block)
        end
        assert unquote(post_block[:do])
        var!(result)
      end
    end
  end

  defmacro precondition(stuff) do
    Module.put_attribute(__CALLER__.module, :__pre__, stuff)
  end

  defmacro postcondition(stuff) do
    Module.put_attribute(__CALLER__.module, :__post__, stuff)
  end

end
