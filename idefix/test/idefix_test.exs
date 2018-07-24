defmodule IdefixTest do
  use ExUnit.Case
  doctest Idefix

  test "greets the world" do
    assert Idefix.hello() == :world
  end
end
