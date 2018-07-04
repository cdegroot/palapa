defmodule Boids.VectorMath do
  @moduledoc """
  Simple helpers to do 2d vector math. Only functions we use (or used
  at one time ;-)) are here.
  """

  @doc "Sum vectors"
  def vsum(vectors) do
    vectors
    |> Enum.reduce(fn {dx, dy}, {sum_dx, sum_dy} -> {dx + sum_dx, dy + sum_dy} end)
  end
  def vsum({x1, y1}, {x2, y2}) do
    {x1 + x2, y1 + y2}
  end

  @doc "Multiply by a scalar"
  def vmul(f, {x, y}), do: vmul({x, y}, f)
  def vmul({x, y}, f), do: {x * f, y * f}
end
