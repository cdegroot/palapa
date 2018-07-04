defmodule Boids.Boid do
  @moduledoc """
  Process simulating a single boid
  """
  use GenServer

  @fps 10 # Update ourselves this often per second
  @fps_sleep_ms 1000 / @fps
  @lifetime 10_000_000 # Expected lifetime of a boid, in microseconds
  @min_lifetime 2_000_000 # Minimum lifetime of a boid

  defmodule State do
    defstruct [:world, :behaviour, :x, :y, :v, :t]
  end

  def start_link(world, initial_behaviour) do
    GenServer.start_link(__MODULE__, {world, initial_behaviour})
  end

  def init({world, initial_behaviour}) do
    x = :rand.uniform()
    y = :rand.uniform()
    v = {:rand.uniform(), :rand.uniform()}
    t = :erlang.monotonic_time(:microsecond)
    t_death = t + max(@min_lifetime, @lifetime * :rand.normal)
    send(self(), :tick)
    Process.send_after(self(), :die, t_death, abs: true)
    Boids.World.add_pos(world, x, y, v)
    Process.flag(:trap_exit, true)
    {:ok, %State{world: world, behaviour: initial_behaviour,
                 x: x, y: y, v: v, t: t}}
  end

  def handle_info(:tick, state) do
    next_time = :erlang.monotonic_time(:millisecond) + @fps_sleep_ms
    Process.send_after(self(), :tick, next_time)
    neighbours = Boids.World.get_neighbours(state.world, state.x, state.y)
    {x, y, v, t} = state.behaviour.make_move(neighbours,
      state.x, state.y, state.v, state.t)
    Boids.World.update_pos(state.world, state.x, state.y, state.v, x, y, v)
    {:noreply, %State{state | x: x, y: y, v: v, t: t}}
  end

  def handle_info(:die, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, state) do
    Boids.World.del_pos(state.world, state.x, state.y, state.v)
  end
end
