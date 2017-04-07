defmodule ECS.Math do
  @moduledoc """
  Vector/matrix math, the stuff that games need.
  """

  @doc """
  vector dot product

  iex> ECS.Math.dot({1, 2, 3}, {4, 5, 6})
  32
  iex> ECS.Math.dot({5, 10, nil}, {12, 13, nil})
  190
  iex> ECS.Math.dot({5, 10}, {12, 13})
  190
  """
  def dot({x1, y1}, {x2, y2}), do: (x1 * x2) + (y1 * y2)
  def dot({x1, y1, nil}, {x2, y2, nil}), do: dot({x1, y1}, {x2, y2})
  def dot({x1, y1, z1}, {x2, y2, z2}), do: (x1 * x2) + (y1 * y2) + (z1 * z2)

  @doc """
  vector/scalar product. As this is commutative, both forms are given
  to make sure that we can stick close to original formulas.

  iex> ECS.Math.product({1, 2, 3}, 4)
  {4, 8, 12}
  iex> ECS.Math.product({3, 12, nil}, 2)
  {6, 24, nil}
  iex> ECS.Math.product({5, 10}, 3)
  {15, 30}
  iex> ECS.Math.product(4, {1, 2, 3})
  {4, 8, 12}
  iex> ECS.Math.product(2, {3, 12, nil})
  {6, 24, nil}
  iex> ECS.Math.product(3, {5, 10})
  {15, 30}

  """
  def product({x, y}, f), do: {x * f, y * f}
  def product({x, y, nil}, f), do: {x * f, y * f, nil}
  def product({x, y, z}, f), do: {x * f, y * f, z * f}
  def product(f, {x, y}), do: {x * f, y * f}
  def product(f, {x, y, nil}), do: {x * f, y * f, nil}
  def product(f, {x, y, z}), do: {x * f, y * f, z * f}

  @doc """
  Subtract vectors

  iex> ECS.Math.subtract({1, 2, 3}, {4, 5, 6})
  {-3, -3, -3}
  iex> ECS.Math.subtract({10, 12}, {8, 9})
  {2, 3}
  iex> ECS.Math.subtract({11, 13, nil}, {8, 6, nil})
  {3, 7, nil}
  """
  def subtract({x1, y1}, {x2, y2}), do: {x1 - x2, y1 - y2}
  def subtract({x1, y1, nil}, {x2, y2, nil}), do: {x1 - x2, y1 - y2, nil}
  def subtract({x1, y1, z1}, {x2, y2, z2}), do: {x1 - x2, y1 - y2, z1 - z2}

  @doc """
  Normalize a vector (make it length 1)

  iex> ECS.Math.norm({1, 0})
  {1.0, 0.0}
  iex> ECS.Math.norm({3, 4})
  {0.6, 0.8}
  iex> ECS.Math.norm({3, 4, nil})
  {0.6, 0.8, nil}
  iex> ECS.Math.norm({3, 4, 5})
  {0.4242640687119285, 0.565685424949238, 0.7071067811865475}
  """
  def norm({x, y}) do
    l = :math.sqrt((x * x) + (y * y))
    {x / l, y / l}
  end
  def norm({x, y, nil}) do
    l = :math.sqrt((x * x) + (y * y))
    {x / l, y / l, nil}
  end
  def norm({x, y, z}) do
    l = :math.sqrt((x * x) + (y * y) + (z * z))
    {x / l, y / l, z / l}
  end

  @doc """
  bounce a ball off a plane. the first argument is the speed
  vector, the second argument the normal of the plane. Returns
  the new speed, assuming no friction and other things.

  v' = v - 2(v dot n)n

  iex> ECS.Math.bounce({1, 1}, {1, 0})
  {-1, 1}
  iex> ECS.Math.bounce({3, 2, 1}, {0, 1, 0})
  {3, -2, 1}
  iex> ECS.Math.bounce({2, 1, 1.5}, {0.4242640687119285, 0.565685424949238, 0.7071067811865475})
  {-0.09999999999999964, -1.7999999999999994, -1.9999999999999991}
  """
  def bounce(v, n), do: subtract(v, product(2 * dot(v, n), n))
end
