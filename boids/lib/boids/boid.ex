defmodule Boids.Boid do
  @moduledoc """
  Process simulating a single boid
  """
  use GenServer
  import Boids.Math

  @fps 50 # Update ourselves this often per second
  @fps_sleep_ms round(1000 / @fps)
  @lifetime 60_000 # Expected lifetime of a boid, in milliseconds
  @min_lifetime 2_000 # Minimum lifetime of a boid

  defmodule State do
    defstruct [:world, :behaviour, :x, :y, :v, :t]
  end

  def start_link(world, initial_behaviour) do
    GenServer.start_link(__MODULE__, {world, initial_behaviour})
  end

  def init({world, initial_behaviour}) do
    x = :rand.uniform()
    y = :rand.uniform()
    v = {:rand.normal() / 5, :rand.normal() / 5}
    t = :erlang.monotonic_time(:microsecond)
    t_death = round(max(@min_lifetime, @lifetime * :rand.normal(1, 0.75)))
    send(self(), :tick)
    Process.send_after(self(), :die, t_death)
    Boids.World.add_pos(world, x, y, v)
    Process.flag(:trap_exit, true)
    IO.puts("Boid #{inspect self}: (#{x}, #{y}, #{inspect v}) scheduled to die in #{t_death}ms")
    {:ok, %State{world: world, behaviour: initial_behaviour,
                 x: x, y: y, v: v, t: t}}
  end

  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, @fps_sleep_ms)
    neighbours = Boids.World.get_neighbours(state.world, state.x, state.y)
    {x, y, v, t} = state.behaviour.make_move(neighbours,
      state.x, state.y, state.v, state.t)
    {x, y} = tbound(x, y)
    Boids.World.update_pos(state.world, state.x, state.y, state.v, x, y, v)
    {:noreply, %State{state | x: x, y: y, v: v, t: t}}
  end

  def handle_info(:die, state) do
    IO.puts("Boid #{inspect self()} is EOL")
    {:stop, :normal, state}
  end

  def terminate(_reason, state) do
    Boids.World.del_pos(state.world, state.x, state.y, state.v)
  end
end
