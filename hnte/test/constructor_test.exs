defmodule ConstructorTest do
  use ExUnit.Case, async: true

  test "Generated constructor should compile" do
    string = Hnte.Constructor.generate(ConstructorTestNetwork, Hnte.RngSensor, Hnte.PrintActuator, [1, 3])
    IO.puts string
  end
end
