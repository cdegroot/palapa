defmodule KalmanTest do
  use ExUnit.Case

  @epsilon 0.00001

  test "perfect signal and estimate with all defaults" do
    k = Kalman.new()
    k = [10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
    |> Enum.reduce(k, fn v, k ->
      Kalman.step(0, v, k)
    end)
    assert_in_delta Kalman.estimate(k), 10.0, @epsilon
  end

  test "numbers from the original elixir package" do
    k = Kalman.new(x: -55)
    k = [-77.0, -76.0, -63.0, -74.0, -66.0, -75.0, -77.0, -63.0, -77.0, -63.0]
    |> Enum.reduce(k, fn v, k ->
      Kalman.step(0, v, k)
    end)

    assert_in_delta Kalman.estimate(k), -69.64323980792942, @epsilon
  end

  test "bad constructor is bad" do
    assert_raise KeyError, fn ->
      Kalman.new(z: 23)
    end
  end
end
