defmodule Boids.Supervisor do
  @moduledoc """
  Supervisor for all the Boid genservers. On `start_link`, this module
  will start a dynamic supervisor with a special monitoring process as
  a first child. This child is responsible for keeping `count` boids
  alive.
  """

  def start_link(world, count, initial_behaviour, next_behaviour) do
    {:ok, pid} = DynamicSupervisor.start_link(strategy: :one_for_one)
    DynamicSupervisor.start_child(pid, %{
          id: Boids.Supervisor,
          start: {Boids.Supervisor, :make_and_monitor_boids,
                  [pid, world, count, initial_behaviour, next_behaviour]}})
    {:ok, pid}
  end

  def make_and_monitor_boids(pid, world, count, initial_behaviour, next_behaviour) do
    1..count
    |> Enum.each(fn _ ->
      {:ok, child} = DynamicSupervisor.start_child(pid, %{
            id: Boids.Boid,
            start: {Boids.Boid, :start_link, [world, initial_behaviour]}})
      Process.monitor(child)
    end)
    monitor_loop(pid, world, next_behaviour)
  end

  defp monitor_loop(pid, world, next_behaviour) do
    receive do
      {:DOWN, _ref, :process, _pid, _reason} ->
        {:ok, child} = DynamicSupervisor.start_child(pid, %{
            id: Boids.Boid,
            start: {Boids.Boid, :start_link, [world, next_behaviour]}})
        Process.monitor(child)
        monitor_loop(pid, world, next_behaviour)
    end
  end
end
