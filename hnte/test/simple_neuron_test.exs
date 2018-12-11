defmodule SimpmleNeuronTest do
  use ExUnit.Case, async: true

  test "basics" do
    {:ok, pid} = Hnte.SimpleNeuron.start_link()

    Hnte.SimpleNeuron.sense(pid, [1, 2])
  end
end
