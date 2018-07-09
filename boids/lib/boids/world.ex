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
  turned out to be quicker. Especially using match specifications, the ETS was
  much faster.
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
    # TODO cleaner ETS table ownership?
    {:ok, Agent.get(pid, & &1)}
  end

  @doc """
  Update position from old position to new position.
  """
  def update_pos(world, new_x, new_y, new_v) do
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
    ms = match_spec(boxes)
    res = :ets.select(world, ms)
    res
  end

  # Convert neighbouring boxes to ETS match specs.
  # http://erlang.org/doc/apps/erts/match_spec.html
  defp match_spec(boxes) do
    # tuples in ETS are {id, x, y, v}
    tuple = {:"$1", :"$2", :"$3", :"$4"}
    Enum.map(boxes, fn {{xl, xh}, {yl, yh}, {xs, ys}} ->
      condition = [{:and,
          {:">=", :"$2", xl},
          {:"<", :"$2", xh},
          {:">=", :"$3", yl},
          {:"<", :"$3", yh},
          {:"/=", :"$1", self()}
        }]
      return = [{{{:+, :"$2", xs}, {:+, :"$3", ys}, :"$4"}}]
      {tuple, condition, return}
    end)
  end

  @doc """
  Return all boids as `{x, y, v}` tuples.
  """
  def get_all(world) do
    all_ms = [{
               {:"_", :"$1", :"$2", :"$3"},
               [],
               [{{:"$1", :"$2", :"$3"}}]
               }]
    :ets.select(world, all_ms)
  end

  # Private but left public for testing.

  # Return the 1, 2, or 4 boxes on the [0,1] torus that are considered
  # neighbours. It returns the lower/upper x and y coordinates, and
  # the x and y shift values for when boxes are transposed.
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
        {{xl, xh}, {yl, yh}, {xshift, yshift}}
    end
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
