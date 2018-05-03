defmodule ControllerTest do
  use ExUnit.Case
  doctest Controller

  test "greets the world" do
    assert Controller.hello() == :world
  end
end
