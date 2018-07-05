defmodule Boids.World do
  @moduledoc """
  World definition for Boids. We stash the locations and directions of
  all boids in an R-Tree we keep in an agent for easy access. This allows
  queries and updates to run mostly inside each Boid's process, thus maximalizing
  parallelism.

  The r-tree library has of course the x and y coordinates and the "opaque value"
  we store in it is a tuple `{velocity, boid_world}`. However, matches will just
  return `{x, y, v}` tuples so this is a mostly internal detail. Velocity is
  stored as a `{dx, dt}` tuple (iow a vector) as that makes calculations simpler.

  The world is modelled as a torus with x and y coordinates in the interval [0, 1] as
  floating points. The neighbourhood radius is fixed (see `@neighbourhood_radius`) and
  determines how far away a boid will check for neighbours to handle its behaviour.
  """

  # TODO handle neighbours correctly. If we're near the origin, then a neighbour on the
  #      torus that sits in the top right is close by and that can be fixed by shifting
  #      the neighbour to negative coordinates, etcetera.
  # TODO filter out dead processes as we cannot always guarantee boids delete themselves

  @doc """
  How far we'll look for neighbours.
  """
  @neighbourhood_radius 0.2

  def start_link() do
    {:ok, pid} = Agent.start_link(fn ->
      :ets.new(:world, [
            :set,
            :public,
            {:read_concurrency, true},
            {:write_concurrency, true}
          ])
    end)
    # We just return the table and let the agent just hum around owning the ETS table.
    {:ok, Agent.get(pid, & &1)}
  end

  @doc """
  Update position from old position to new position.
  """
  def update_pos(world, old_x, old_y, old_v, new_x, new_y, new_v) do
    item = mkitem(new_x, new_y, new_v)
    :ets.insert(world, item)
  end

  @doc """
  Add an initial position
  """
  def add_pos(world, x, y, v, id \\ self()) do
    item = mkitem(x, y, v, id)
    :ets.insert(world, item)
  end

  @doc """
  Remove a position (when boid dies)
  """
  def del_pos(world, _x, _y, _v) do
    :ets.delete(world, self())
  end

  @doc """
  Get the neighbours. Returns a list of {x, y, velocity} tuples.
  This can cause up to four queries depending on whether the bounding
  box overlaps with any of the edges.
  """
  def get_neighbours(world, x, y) do
    boxes = neighbouring_boxes(x, y)
    matches = :ets.foldl(fn {id, x, y, v}, acc ->
      if id != self() do
        {{sx, sy}, is_within} = is_within_boxes?(boxes, x, y)
        if is_within do
          [{x + sx, y + sy, v} | acc]
        else
          acc
        end
      else
        acc
      end
    end, [], world)
  end

  defp is_within_boxes?(boxes_and_shifts, x, y) do
    bas = boxes_and_shifts
    |> Enum.find(fn {[{xl, xh}, {yl, yh}], shift} ->
      xl <= x and x < xh and yl <= y and y < yh
    end)
    case bas do
      nil -> {{0, 0}, false}
      {[xs, ys], shift} -> {shift, true}
    end
  end

  @doc """
  Return all boids as `{x, y, v}` tuples.
  """
  def get_all(world) do
    :ets.foldl(fn {id, x, y, v}, acc ->
      [{x, y, v} | acc]
    end, [], world)
  end

  # Private but left public for testing.

  def neighbouring_boxes(x, y) do
    {x_l, x_h} = {x - @neighbourhood_radius, x + @neighbourhood_radius}
    {y_l, y_h} = {y - @neighbourhood_radius, y + @neighbourhood_radius}

    x_splits = split(x_l, x_h)
    y_splits = split(y_l, y_h)
    combine_boxes(x_splits, y_splits)
  end

  # Spit ranges or not around the borders of the torus. Note that as the centerpoint
  # should always be on the torus, we cannot have a bounding box completely outside it.
  # We return triplets: the search range and how results should be shifted
  defp split(low, high) when low < 0.0, do: [{1.0 + low, 1.0, -1.0}, {0.0, high, 0.0}]
  defp split(low, high) when high > 1.0, do: [{0, high - 1.0, +1.0}, {low, 1.0,  0.0}]
  defp split(low, high), do: [{low, high, 0.0}]

  defp combine_boxes(xs, ys) do
    for {xl, xh, xshift} <- xs,
        {yl, yh, yshift} <- ys do
        {[{xl, xh}, {yl, yh}], {xshift, yshift}}
    end
  end

  defp geos_to_boids(geos) do
    geos
    |> Enum.map(&geo_to_boid/1)
  end
  defp geo_to_boid({:geometry, _2d, [{x, x}, {y, y}], {_boid_pid, v}}) do
      {x, y, v}
  end
  defp apply_shift({x, y, v}, {dx, dy}) do
    {x + dx, y + dy, v}
  end

  # Always call mkitem in the context of the caller so self() is the actual boid
  # that's calling us.
  defp mkitem(x, y, v, id \\ self()) do
    {id, x, y, v}
  end

  # For testing/debugging
  def get_tree(world) do
    Agent.get(world, fn tree -> tree end)
  end
end
