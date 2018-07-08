defmodule Boids.World do
  @moduledoc """
  World definition for Boids. We stash the locations and directions of
  all boids in a central location for easy access. It is in essence a
  blackboard where Boids keep their position for others to act on.

  The world is modelled as a torus with x and y coordinates in the interval [0, 1] as
  floating points. The neighbourhood radius is fixed (see `@neighbourhood_radius`) and
  determines how far away a boid will check for neighbours to handle its behaviour.

  Implementation notes: initially, I started using an r-tree library but I wasn't
  super happy about the result. A plain ETS table with a full table scan for fetches
  turned out to be quicker. On my 2011 MBP, the fetch is around 56us and an update -
  which was quite slow in the r-tree version - is only 22us.

  Interestingly enough, the "boid" behaviour - all the scary math stuff - only takes 7us
  meaning that this module is the bottleneck in two ways: it's slowest linearly, and it's the
  shared mutable state. Some ideas:
  * Use 100 genservers on a grid each responsible for a 0.1x0.1 area keeping data in a Map. a
    Map insert however seems to be slower than an ETS insert.
  * Use multiple ETS tables so we don't need to loop through 100 entries, sort of poor man's
    tree. However, unless you go to silly fine-grained tables, most boids flock together so
    you're probably still looking at most entries.
  * Probably a nice jump in performance: move from `foldl` to at least pre-selecting most
    neighbours with `match`. Match specifications run inside the BIF bits of ETS so should
    be quite a bit faster than looping with `fold`
  """

  # TODO filter out dead processes as we cannot always guarantee boids delete themselves?

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
