defmodule Boids do
  @moduledoc """
  Main API for Boids behaviour.
  """

  @doc """
  Starts a new simulation. Parameters:
  * `count`: the number of boids to start
  * `initial_behaviour`: the behaviour for the initial generation
  * `next_behaviour`: the behaviour for follow-up generations

  Returns something opaque that should be handed to other API calls as well.
  * `{:ok, simulation}`: everything went well
  """

  @c Boids.CirclingBehaviour
  @f Boids.FlockingBehaviour

  def start_link(count \\ 50,
                 initial_behaviour \\ @c,
                 next_behaviour \\ @f) do
    {:ok, world} = Boids.World.start_link()
    {:ok, pid} = Boids.Supervisor.start_link(world, count, initial_behaviour, next_behaviour)
    {:ok, {world, pid}}
  end

  @doc """
  Returns current boids as `{x, y, {vx, vy}}` tuples.
  """
  def get_all({world, _}) do
    Boids.World.get_all(world)
  end
end
