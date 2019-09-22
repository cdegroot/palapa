defmodule ControlTest do
  use ExUnit.Case
  doctest Control

  test "greets the world" do
    assert Control.hello() == :world
  end
end
