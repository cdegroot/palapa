defmodule SimplestNnTest do
  use ExUnit.Case, async: true

  test "basics" do
    {:ok, sensor} = Hnte.SimplestNn.Cortex.start_link()
    Hnte.SimplestNn.Sensor.trigger(sensor)
    Process.sleep(1_000)
  end
end
