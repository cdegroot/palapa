defmodule Boids.Supervisor do
  @moduledoc """
  Supervisor for all the Boid genservers. On `start_link`, this module
  will start a dynamic supervisor that hopefully keeps the boids alive :)

  TODO: figure out how to switch from initial behaviour to next behaviour.
  """

  def start_link(world, count, initial_behaviour, next_behaviour) do
    {:ok, pid} = DynamicSupervisor.start_link(strategy: :one_for_one, max_restarts: 200)
    IO.puts("Started supervisor as #{inspect pid}")
    1..count
    |> Enum.each(fn _ ->
      IO.puts("{{#{count}")
      retval = DynamicSupervisor.start_child(pid, %{
            id: Boids.Boid,
            start: {Boids.Boid, :start_link, [world, initial_behaviour]}})
      IO.inspect(retval)
      IO.puts("}}")
    end)
    {:ok, pid}
  end
end
