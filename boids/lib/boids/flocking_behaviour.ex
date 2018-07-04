defmodule Boids.FlockingBehaviour do
  @moduledoc """
  Boids Flocking behaviour. This is the well-known simulation
  where the boids follow three rules:

  1. Boids try to fly towards the centre of mass of neighbouring boids.
  2. Boids try to keep a small distance away from other objects (including other boids).
  3. Boids try to match velocity with near boids.

  Code below is mostly a direct interpretation of http://www.kfish.org/boids/pseudocode.html
  """

  import Boids.VectorMath

  @r1_adj 100       # The larger this is, the smaller the effect of rule one
  @r2_min_dist 0.05 # When we consider a boid "too close"
  @r3_adj 8         # The larger this is, the smaller the effect or rule three

  @doc """
  Calculate a single move. Called by a boid that wants to update its position. It
  passes the previous time it made a move so that we can make precise adjustments
  based on the time passed since then. Timestamps are microsecond precision here.
  """
  def make_move(neighbours, my_x, my_y, my_v = {_vx, _vy},
                prev_t, t \\ :erlang.monotonic_time(:microsecond)) do
    delta_t = t - prev_t
    t_fraction = delta_t / 1_000_000
    v1 = vmul(t_fraction, rule_one(neighbours, my_x, my_y))
    v2 = vmul(t_fraction, rule_two(neighbours, my_x, my_y))
    v3 = vmul(t_fraction, rule_three(neighbours, my_v))
    new_v = vsum([my_v, v1, v2, v3])
    {new_x, new_y} = vsum({my_x, my_y}, new_v)
    {new_x, new_y, new_v, t}
  end

  # Private functions, left public for testing.

  # Return a velocity adjustment to fly towards the centre of mass
  def rule_one(neighbours, my_x, my_y) do
    {sum_x, sum_y, n} = neighbours
    |> Enum.reduce({0, 0, 0}, fn {sum_x, sum_y, n}, {x, y, _v} ->
      {sum_x + x, sum_y + y, n + 1}
    end)
    {center_x, center_y} = {sum_x / n, sum_y / n}
    {_dx, _dy} = {center_x - my_x / @r1_adj,
                  center_y - my_y / @r1_adj}
  end

  # Return a velocity adjustment to keep minumum distance
  def rule_two(neighbours, my_x, my_y) do
    {_dx, _dy} = neighbours
    |> Enum.reduce({0, 0}, fn {dx, dy}, {x, y, _v} ->
      x_dist = my_x - x
      y_dist = my_y - y
      dist = :math.sqrt(x_dist * x_dist + y_dist * y_dist)
      if dist < @r2_min_dist do
        {dx - x_dist, dy - y_dist}
      else
        {dx, dy}
      end
    end)
  end

  # Return a velocity adjustment to match neighbouring boids
  def rule_three(neighbours, {my_vx, my_vy}) do
    {sum_vx, sum_vy, n} = neighbours
    |> Enum.reduce({0, 0, 0}, fn {sum_vx, sum_vy, n}, {_x, _y, {vx, vy}} ->
      {sum_vx + vx, sum_vy + vy, n + 1}
    end)
    {((sum_vx / n) - my_vx) / @r3_adj,
     ((sum_vy / n) - my_vy) / @r3_adj}
  end
end
