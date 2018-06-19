defmodule BoidsUi do
  @moduledoc """
  This modules draws the Boids display
  """
  use Clixir
  @clixir_header "boids_ui"

  # Triangle points
  @triangle [
    {0.0, -0.5},
    {2.0, 0.0},
    {0.0, 0.5}
  ]

  @doc """
  Render, currently a single boid. x, y is the location of the boid,
  direction is its current flying direction (in radians. We're doing Math
  here. k?)
  """
  def render(win_width, win_height, x, y, direction) do
    # Let's try this in Elixir first.
    # Take a triangle
    [{x1, y1}, {x2, y2}, {x3, y3}] = @triangle
    # Rotate it around the origin
    |> Enum.map(&(rotate(&1, direction)))
    # Scale it to reflect win_width, win_height
    |> Enum.map(&(scale(&1, win_width, win_height)))
    # Move it to x, y
    |> Enum.map(&(move(&1, x, y)))
    # Flip the y axis
    |> Enum.map(&(flip_y(&1, win_height)))
    draw_boid(x1, y1, x2, y2, x3, y3)
  end

  @pi :math.pi()

  defp rotate({x, y}, θ) do
    import :math
    {x * cos(θ) - y * sin(θ),
     y * cos(θ) + x * sin(θ)}
  end

  defp scale({x, y}, win_width, win_height) do
    # Some random number we punch in and tweak. The normalized triangle
    # is 2 high and 1 width.
    {x * (win_width / 50),
     y * (win_height / 50)}
  end

  defp move({x, y}, target_x, target_y) do
    {x + target_x,
     y + target_y}
  end

  defp flip_y({x, y}, win_height), do: {x, win_height - y}

  def_c draw_boid(x1, y1, x2, y2, x3, y3) do
    cdecl double: [x1, y1, x2, y2, x3, y3]

    nvgBeginPath(vg)
    nvgMoveTo(vg, x1, y1)
    nvgLineTo(vg, x2, y2)
    nvgLineTo(vg, x3, y3)
    nvgFillColor(vg, nvgRGBA(128, 192, 192, 255))
    nvgFill(vg)
	  nvgStrokeColor(vg, nvgRGBA(192, 128, 128, 255))
	  nvgStroke(vg)
  end
end
