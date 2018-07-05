defmodule PerformanceTest do
  use ExUnit.Case, async: false # run only the performance test, please

  @grid 10 # Usually a hundred boids is sort of a reasonable max

  import Boids.World
  import Boids.Math

  test "Timer stuff" do
    {:ok, world} = Boids.World.start_link()
    for x <- 1..@grid,
        y <- 1..@grid do
        add_pos(world, x/@grid, y/@grid, {x, y}, :rand.normal())
    end
    # Add self.
    add_pos(world, 0.49, 0.49, {0.1, 0.1})
    {t_fetch, _} = :timer.tc(fn ->
      Enum.each(0..1000, fn _ ->
        get_neighbours(world, 0.49, 0.49)
      end)
    end)
    IO.puts("1000 neighbour fetches: #{t_fetch}us, #{t_fetch/1000}us/iteration")

    neighbours = get_neighbours(world, 0.49, 0.49)
    {t_move, _} = :timer.tc(fn ->
      Enum.reduce(0..1000, {0.49, 0.49, {0.1, 0.1}, 0}, fn _, {x, y, v, _t} ->
        # We cycle the numbers through the function to make sure that caching isn't
        # going to mess things up
        Boids.FlockingBehaviour.make_move(neighbours, x, y, v, 0, 20000)
      end)
    end)
    IO.puts("1000 flocking moves: #{t_move}us, #{t_move/1000}us/iteration")

    {t_update, _} = :timer.tc(fn ->
      Enum.each(0..1000, fn i ->
        {old_x, old_y} = tbound(0.49 + (i / 100), 0.49 - (i/100))
        {new_x, new_y} = tbound(0.49 + ((i + 1) / 100), 0.49 - ((i + 1)/100))
        update_pos(world, old_x, old_y, {0.1, 0.1},
                          new_x, new_y, {0.1, 0.1})
      end)
    end)
    IO.puts("1000 updates: #{t_update}us, #{t_update/1000}us/iteration")

    t_total = t_fetch + t_move + t_update
    t_each = t_total/1000
    IO.puts("1000 runs: #{t_total}us, #{t_each}us/iteration")
    time_per_frame = 1_000_000 / 50
    IO.puts("Limit at 50fps: #{time_per_frame / t_each}")
  end
end
