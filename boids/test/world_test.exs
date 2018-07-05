defmodule WorldTest do
  use ExUnit.Case, async: true

  import Boids.World

  @epsilon 0.0001

  # tests keep x coords odd, y coords even so we can easily spot code mistakes

  test "Neighbouring boxes, no split" do
    compare_with_epsilon(neighbouring_boxes(0.5, 0.4),
      [
        {[{0.3, 0.7}, {0.2, 0.6}], {0.0, 0.0}}
      ])
  end

  test "Neighbouring boxes, left split" do
    compare_with_epsilon(neighbouring_boxes(0.1, 0.4),
      [{[{0.9, 1.0}, {0.2, 0.6}], {-1.0, 0.0}},
       {[{0.0, 0.3}, {0.2, 0.6}], { 0.0, 0.0}}])
  end

  test "Neighbouring boxes, right split" do
    compare_with_epsilon(neighbouring_boxes(0.9, 0.4),
      [{[{0.0, 0.1}, {0.2, 0.6}], {1.0, 0.0}},
       {[{0.7, 1.0}, {0.2, 0.6}], {0.0, 0.0}}])
  end

  test "Neighbouring boxes, top split" do
    compare_with_epsilon(neighbouring_boxes(0.5, 0.02),
      [{[{0.3, 0.7}, {0.82, 1.0}], {0.0, -1.0}},
       {[{0.3, 0.7}, {0.0, 0.22}], {0.0, 0.0}}])
  end

  test "Neighbouring boxes, bottom split" do
    compare_with_epsilon(neighbouring_boxes(0.5, 0.82),
      [{[{0.3, 0.7}, {0.0, 0.02}], {0.0, 1.0}},
       {[{0.3, 0.7}, {0.62, 1.0}], {0.0, 0.0}}])
  end

  test "Neighbouring boxes, top left split" do
    compare_with_epsilon(neighbouring_boxes(0.1, 0.02),
      [{[{0.9, 1.0}, {0.82, 1.0}], {-1.0, -1.0}},
       {[{0.9, 1.0},  {0.0, 0.22}], {-1.0, 0.0}},
       {[{0.0, 0.3}, {0.82, 1.0}], {0.0, -1.0}},
       {[{0.0, 0.3},  {0.0, 0.22}], {0.0, 0.0}}])
  end

  test "Neighbouring boxes, top right split" do
    compare_with_epsilon(neighbouring_boxes(0.1, 0.82),
      [{[{0.9, 1.0},  {0.0, 0.02}], {-1.0, 1.0}},
       {[{0.9, 1.0}, {0.62, 1.0}], {-1.0, 0.0}},
       {[{0.0, 0.3},  {0.0, 0.02}], {0.0, 1.0}},
       {[{0.0, 0.3}, {0.62, 1.0}], {0.0, 0.0}}])
  end

  test "Neighbouring boxes, bottom left split" do
    compare_with_epsilon(neighbouring_boxes(0.9, 0.02),
      [{[{0.0, 0.1}, {0.82, 1.0}], {1.0, -1.0}},
       {[{0.0, 0.1},  {0.0, 0.22}], {1.0, 0.0}},
       {[{0.7, 1.0}, {0.82, 1.0}], {0.0, -1.0}},
       {[{0.7, 1.0},  {0.0, 0.22}], {0.0, 0.0}}])
  end

  test "Neighbouring boxes, bottom right split" do
  #  IO.inspect(neighbouring_boxes(0.1, 0.02))
    compare_with_epsilon(neighbouring_boxes(0.9, 0.82),
      [{[{0, 0.1},    {0.0, 0.02}], {1.0, 1.0}},
       {[{0, 0.1},   {0.62, 1.0}], {1.0, 0.0}},
       {[{0.7, 1.0},  {0.0, 0.02}], {0.0, 1.0}},
       {[{0.7, 1.0}, {0.62, 1.0}], {0.0, 0.0}}])
  end

  @grid 10

  test "World integration test" do
    {:ok, world} = Boids.World.start_link()
    for x <- 1..@grid,
        y <- 1..@grid do
       add_pos(world, x/@grid, y/@grid, {x, y}, :rand.normal())
    end
    # Property based testing. The delta test always holds as
    # points on the far side of the torus are shifted around to
    # be "next" to the get_neighbours arguments.
    for my_x <- 1..@grid,
        my_y <- 1..@grid do
        world
        |> get_neighbours(my_x/@grid, my_y/@grid)
        |> Enum.each(fn {x, y, _v} ->
          assert_in_delta x, my_x/@grid, 0.20001, "#{x} and #{my_x/@grid} not within delta (y = #{y}, #{my_y/@grid})"
          assert_in_delta y, my_y/@grid, 0.20001, "#{y} and #{my_y/@grid} not within delta (x = #{x}, #{my_x/@grid})"
        end)
    end
  end

  defp compare_with_epsilon([], []), do: nil
  defp compare_with_epsilon([h1|t1], [h2|t2]) do
    compare_with_epsilon(h1, h2)
    compare_with_epsilon(t1, t2)
  end
  defp compare_with_epsilon({coords_l, shifts_l}, {coords_r, shifts_r}) do
    compare_with_epsilon(coords_l, coords_r)
    compare_with_epsilon(shifts_l, shifts_r)
    #assert_in_delta(x1, x2, @epsilon)
    #assert_in_delta(y1, y2, @epsilon)
  end
  defp compare_with_epsilon(s1, s2) do
    assert_in_delta(s1, s2, @epsilon)
  end
end
