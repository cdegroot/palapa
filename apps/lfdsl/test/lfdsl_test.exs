defmodule LfdslTest do
  use ExUnit.Case
  doctest Lfdsl

  test "the truth" do
    code = ~s/(: io_lib format '"Hello World!~n" ())/
    {:ok, form} = :lfe_io.read_string(code |> String.to_charlist)
    IO.inspect(form)
    mod = :lfe_gen.new_module(:some_module)
    mod = :lfe_gen.add_exports([gogogo: 0], mod)
    mod = :lfe_gen.add_form([:defun, :gogogo, [], form], mod)
    {:ok, :some_module, binary, warnings} = :lfe_gen.compile_mod(mod)
    :code.load_binary(:some_module, 'nofile', binary)

    assert ('Hello World!' ++ ['\n']) == :some_module.gogogo()
  end
end
