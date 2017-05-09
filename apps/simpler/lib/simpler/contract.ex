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
    Logger.error("     def! #{inspect body}")
    Logger.error("     pre: #{inspect Module.get_attribute(__CALLER__.module, :__pre__)}")
    Logger.error("    post: #{inspect Module.get_attribute(__CALLER__.module, :__post__)}")
    {name, _, args} = name_and_args
    do_block = body[:do]
    Logger.error("      do: #{inspect do_block}")
    pre_block = Module.get_attribute(__CALLER__.module, :__pre__) || [do: true]
    post_block = Module.get_attribute(__CALLER__.module, :__post__) || [do: true]
    quote do
      Kernel.def unquote(name)(unquote_splicing(args)) do
        assert unquote(pre_block[:do])
        unquote(do_block)
      end
    end
  end

  defmacro precondition(stuff) do
    Logger.error("Precondition! #{inspect stuff}")
    Module.put_attribute(__CALLER__.module, :__pre__, stuff)
  end

  defmacro postcondition(stuff) do
    Logger.error("Postcondition! #{inspect stuff}")
    Module.put_attribute(__CALLER__.module, :__post__, stuff)
  end

end
