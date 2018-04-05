defmodule UderzoTest do
  use ExUnit.Case
  doctest Uderzo

  test "greets the world" do
    assert Uderzo.hello() == :world
  end
end
