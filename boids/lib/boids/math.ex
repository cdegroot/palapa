defmodule Boids.Math do
  @moduledoc """
  Simple helpers to do 2d vector math and torus stuff. Only functions we use (or used
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

  @doc "Keep coordinates on a torus"
  def tbound(v), do: v - Float.floor(v)
  def tbound(x, y), do: {tbound(x), tbound(y)}

  @doc "Limit vector to a maximum size"
  def vmax({x, y}, max) do
    size = :math.sqrt((x * x) + (y * y))
    if size > max do
      reduction = size / max
      {x / reduction, y / reduction}
    else
      {x, y}
    end
  end
end
