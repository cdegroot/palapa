defmodule Boids.Supervisor do
  @moduledoc """
  Supervisor for all the Boid genservers. On `start_link`, this module
  will start a dynamic supervisor that hopefully keeps the boids alive :)

  For visualization reasons, you can specify two different behaviours. The
  first "generation" gets the initial behaviour, subsequent boids get the
  final behaviour.
  """


  def start_link(world, count, initial_behaviour, final_behaviour) do
    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one, max_restarts: 200)
    1..count
    |> Enum.each(fn count ->
      Task.start(fn ->
        # First we start the boid by hand for its initial behaviour. When it dies,
        # we start it under the dynamic supervisor.
        {:ok, boid} = Boids.Boid.start_link(world, initial_behaviour)
        Process.monitor(boid)
        receive do
          {:DOWN, _ref, :process, ^boid, _reason} ->
            IO.puts("Moving Boid ##{count} to final behaviour")
            DynamicSupervisor.start_child(supervisor, %{
                  id: :"Boid##{count}",
                  start: {Boids.Boid, :start_link, [world, final_behaviour]}})
        end
      end)
    end)
    {:ok, supervisor}
  end
end
