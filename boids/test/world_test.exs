defmodule WorldTest do
  use ExUnit.Case, async: true

  import Boids.World

  @epsilon 0.0001

  # tests keep x coords odd, y coords even so we can easily spot code mistakes

  test "Neighbouring boxes, no split" do
    compare_with_epsilon(neighbouring_boxes(0.5, 0.4),
      [[{0.3, 0.2}, {0.7, 0.6}]])
  end

  test "Neighbouring boxes, left split" do
    compare_with_epsilon(neighbouring_boxes(0.1, 0.4),
      [[{0.9, 0.2}, {1.0, 0.6}],
       [{0.0, 0.2}, {0.3, 0.6}]])
  end

  test "Neighbouring boxes, right split" do
    compare_with_epsilon(neighbouring_boxes(0.9, 0.4),
      [[{0.0, 0.2}, {0.1, 0.6}],
       [{0.7, 0.2}, {1.0, 0.6}]])
  end

  test "Neighbouring boxes, top split" do
    compare_with_epsilon(neighbouring_boxes(0.5, 0.02),
      [[{0.3, 0.82}, {0.7, 1.0}],
       [{0.3, 0.0}, {0.7, 0.22}]])
  end

  test "Neighbouring boxes, bottom split" do
    compare_with_epsilon(neighbouring_boxes(0.5, 0.82),
      [[{0.3, 0.0}, {0.7, 0.02}],
       [{0.3, 0.62}, {0.7, 1.0}]])
  end

  test "Neighbouring boxes, top left split" do
    compare_with_epsilon(neighbouring_boxes(0.1, 0.02),
      [[{0.9, 0.82}, {1.0, 1.0}],
       [{0.9, 0.0},  {1.0, 0.22}],
       [{0.0, 0.82}, {0.3, 1.0}],
       [{0.0, 0.0},  {0.3, 0.22}]])
  end

  test "Neighbouring boxes, top right split" do
    compare_with_epsilon(neighbouring_boxes(0.1, 0.82),
      [[{0.9, 0},    {1.0, 0.02}],
       [{0.9, 0.62}, {1.0, 1.0}],
       [{0.0, 0},    {0.3, 0.02}],
       [{0.0, 0.62}, {0.3, 1.0}]])
  end

  test "Neighbouring boxes, bottom left split" do
    compare_with_epsilon(neighbouring_boxes(0.9, 0.02),
      [[{0, 0.82},   {0.1, 1.0}],
       [{0, 0.0},    {0.1, 0.22}],
       [{0.7, 0.82}, {1.0, 1.0}],
       [{0.7, 0.0},  {1.0, 0.22}]])
  end

  test "Neighbouring boxes, bottom right split" do
    compare_with_epsilon(neighbouring_boxes(0.9, 0.82),
      [[{0, 0},      {0.1, 0.02}],
       [{0, 0.62},   {0.1, 1.0}],
       [{0.7, 0},    {1.0, 0.02}],
       [{0.7, 0.62}, {1.0, 1.0}]])
  end
  defp compare_with_epsilon([], []), do: nil
  defp compare_with_epsilon([h1|t1], [h2|t2]) do
    compare_with_epsilon(h1, h2)
    compare_with_epsilon(t1, t2)
  end
  defp compare_with_epsilon({x1, y1}, {x2, y2}) do
    assert_in_delta(x1, x2, @epsilon)
    assert_in_delta(y1, y2, @epsilon)
  end

  test "World integration test" do
    # TODO way more data items, fill a grid systematically
    {:ok, world} = Boids.World.start_link()
    add_pos(world, 0.1, 0.8, {1.0, 1.5})
    add_pos(world, 0.3, 0.6, {2.0, 2.5})
    add_pos(world, 0.5, 0.4, {3.0, 3.5})
    add_pos(world, 0.7, 0.2, {4.0, 4.5})
    assert get_neighbours(world, 0.2, 0.5) == [{0.3, 0.6, {2.0, 2.5}}]
  end
end
