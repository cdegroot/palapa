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

  # TODO filter out dead processes as we cannot always guarantee boids delete themselves

  @doc """
  How far we'll look for neighbours.
  """
  @neighbourhood_radius 0.4

  def start_link() do
    Agent.start_link(fn -> :rstar.new(2) end)
  end

  @doc """
  Update position from old position to new position.
  """
  def update_pos(world, old_x, old_y, old_v, new_x, new_y, new_v) do
    old_item = mkitem(old_x, old_y, old_v)
    new_item = mkitem(new_x, new_y, new_v)
    Agent.update(world, fn rtree ->
      rtree = :rstar.delete(rtree, old_item)
      :rstar.insert(rtree, new_item)
    end)
  end

  @doc """
  Add an initial position
  """
  def add_pos(world, x, y, v) do
    item = mkitem(x, y, v)
    Agent.update(world, fn rtree ->
      :rstar.insert(rtree, item)
    end)
  end

  @doc """
  Remove a position (when boid dies)
  """
  def del_pos(world, x, y, v) do
    item = mkitem(x, y, v)
    Agent.update(world, fn rtree ->
      :rstar.delete(rtree, item)
    end)
  end

  @doc """
  Get the neighbours. Returns a list of {x, y, velocity} tuples.
  This can cause up to four queries depending on whether the bounding
  box overlaps with any of the edges.
  """
  def get_neighbours(world, x, y) do
    boxes = neighbouring_boxes(x, y)
    geos = Enum.map(boxes, fn box -> :rstar_geometry.new(2, box, nil) end)
    world
    |> Agent.get(fn rtree ->
      Enum.map(geos, fn geo ->
        :rstar.search_within(rtree, geo)
      end)
    end)
    # TODO filter down from a box to a circle
    |> List.flatten()
    |> Enum.reject(fn {:geometry, 2, _coords, {pid, _v}} ->
      pid == self()
    end)
    |> geos_to_boids()
  end


  @doc """
  Return all boids as `{x, y, v}` tuples.
  """
  def get_all(world) do
    big_box = :rstar_geometry.new(2, [{-2.0, 2.0}, {-2.0, 2.0}], nil)
    world
    |> Agent.get(fn rtree ->
      :rstar.search_within(rtree, big_box)
    end)
    |> geos_to_boids()
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
  defp split(low, high) when low < 0.0, do: [{1.0 + low, 1.0}, {0.0, high}]
  defp split(low, high) when high > 1.0, do: [{0, high - 1.0}, {low, 1.0}]
  defp split(low, high), do: [{low, high}]

  defp combine_boxes(xs, ys) do
    for xlh <- xs,
        ylh <- ys do
        [xlh, ylh]
    end
  end

  defp geos_to_boids(geos) do
    geos
    |> Enum.map(fn {:geometry, _2d, [{x, x}, {y, y}], {_boid_pid, v}} ->
      {x, y, v}
    end)
  end

  # Always call mkitem in the context of the caller so self() is the actual boid
  # that's calling us.
  defp mkitem(x, y, v) do
    :rstar_geometry.point2d(x, y, {self(), v})
  end

  # For testing/debugging
  def get_tree(world) do
    Agent.get(world, fn tree -> tree end)
  end
end
