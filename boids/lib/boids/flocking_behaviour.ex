defmodule Boids.FlockingBehaviour do
  @moduledoc """
  Boids Flocking behaviour. This is the well-known simulation
  where the boids follow three rules:

  1. Boids try to fly towards the centre of mass of neighbouring boids.
  2. Boids try to keep a small distance away from other objects (including other boids).
  3. Boids try to match velocity with near boids.

  Code below is mostly a direct interpretation of http://www.kfish.org/boids/pseudocode.html
  """

  import Boids.Math

  @r1_adj 25       # The larger this is, the slower boids move to each other
  @r2_min_dist 0.05 # When we consider a boid "too close"
  @r3_adj 4         # The larger this is, the slower boids match velocity

  @vmax 0.2

  @doc """
  Calculate a single move. Called by a boid that wants to update its position. It
  passes the previous time it made a move so that we can make precise adjustments
  based on the time passed since then. Timestamps are microsecond precision here.
  """
  def make_move(neighbours, my_x, my_y, my_v = {_vx, _vy},
                prev_t, t \\ :erlang.monotonic_time(:microsecond)) do
    t_fraction = (t - prev_t) / 1_000_000
    v1 = vmul(t_fraction, rule_one(neighbours, my_x, my_y))
    v2 = vmul(t_fraction, rule_two(neighbours, my_x, my_y))
    v3 = vmul(t_fraction, rule_three(neighbours, my_v))
    new_v = [my_v, v1, v2, v3] |> vsum() |> vmax(@vmax)
    #if {v1, v2, v3} != {{0.0,0.0},{0.0,0.0},{0.0,0.0}} do
      #IO.puts("#{t_fraction}: #{inspect my_v} + #{inspect v1},#{inspect v2},#{inspect v3} => #{inspect new_v}")
    #end
    {new_x, new_y} = vsum({my_x, my_y}, vmul(new_v, t_fraction))
    {new_x, new_y, new_v, t}
  end

  # Private functions, left public for testing.

  # Return a velocity adjustment to fly towards the centre of mass
  def rule_one([], _, _) do
    {0, 0}
  end
  def rule_one(neighbours, my_x, my_y) do
    {sum_x, sum_y, n} = neighbours
    |> Enum.reduce({0, 0, 0}, fn {x, y, _v}, {sum_x, sum_y, n} ->
      {sum_x + x, sum_y + y, n + 1}
    end)
    {center_x, center_y} = {sum_x / n, sum_y / n}
    {dx, dy} = {(center_x - my_x) / @r1_adj,
                (center_y - my_y) / @r1_adj}
    #IO.puts("rule_one: #{my_x},#{my_y} -> #{center_x},#{center_y} = #{dx},#{dy}")
    {dx, dy}
  end

  # Return a velocity adjustment to keep minumum distance
  def rule_two([], _, _) do
    {0, 0}
  end
  def rule_two(neighbours, my_x, my_y) do
    {_dx, _dy} = neighbours
    |> Enum.reduce({0, 0}, fn {x, y, _v}, {dx, dy} ->
      x_dist = x - my_x
      y_dist = y - my_y
      dist = :math.sqrt(x_dist * x_dist + y_dist * y_dist)
      if dist < @r2_min_dist do
        {dx - x_dist, dy - y_dist}
      else
        {dx, dy}
      end
    end)
  end

  # Return a velocity adjustment to match neighbouring boids
  def rule_three([], _) do
    {0, 0}
  end
  def rule_three(neighbours, {my_vx, my_vy}) do
    {sum_vx, sum_vy, n} = neighbours
    |> Enum.reduce({0, 0, 0}, fn {_x, _y, {vx, vy}}, {sum_vx, sum_vy, n} ->
      {sum_vx + vx, sum_vy + vy, n + 1}
    end)
    {dx, dy} = {((sum_vx / n) - my_vx) / @r3_adj,
                ((sum_vy / n) - my_vy) / @r3_adj}
    #IO.puts("rule 3: #{my_vx},#{my_vy} ~ #{sum_vx/n},#{sum_vy/n} = #{dx},#{dy}")
    {dx, dy}
  end
end
