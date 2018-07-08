defmodule BoidsUi do
  @moduledoc """
  This modules draws the Boids display
  """
  use Clixir
  @clixir_header "boids_ui"

  # Our basic boid representation, pointing right.
  @triangle [
    {0.0, -0.2},
    {1.0, 0.0},
    {0.0, 0.2}
  ]

  @doc """
  Paint the background some blue sky color with a sun.
  """
  def_c paint_background(win_width, win_height) do
    cdecl double: [win_width, win_height]
    cdecl "NVGpaint": air
    cdecl "NVGpaint": sun

    air = nvgLinearGradient(vg, win_width / 2, 0, win_width / 2, win_height, nvgRGBA(0, 64, 196, 255), nvgRGBA(0, 196, 255, 255))
    #air = nvgLinearGradient(vg, win_width / 2, 0, win_width / 2, win_height, nvgRGBA(0, 0, 128, 255), nvgRGBA(128, 64, 0, 255))
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, win_width, win_height)
    nvgFillPaint(vg, air)
    nvgFill(vg)

    sun = nvgRadialGradient(vg, win_width * 0.8, win_height * 0.2, 0.04 * win_width, 0.05 * win_width, nvgRGBA(255, 255, 0, 255), nvgRGBA(128, 128, 0, 0))

    nvgBeginPath(vg)
    nvgCircle(vg, win_width * 0.8, win_height * 0.2, 0.1 * win_width)
    nvgFillPaint(vg, sun)
    nvgFill(vg)
  end

  @doc """
  Render, currently a single boid. x, y is the location of the boid,
  velocity is its current flying direction as a vector `{vx, vy}`.
  """
  def render(win_width, win_height, x, y, {vx, vy}) do
    # Let's try this in Elixir first.
    # Take a triangle
    direction = :math.atan2(vy, vx)
    [{x1, y1}, {x2, y2}, {x3, y3}] = @triangle
    |> Enum.map(fn point ->
      point
      |> rotate(direction)                   # Rotate it around the origin
      |> scale(win_width, win_height)        # Scale it to reflect win_width, win_height
      |> move(x * win_width, y * win_height) # Move it to x, y scaled to window size
      |> flip_y(win_height)                  # Flip the y axis as Uderzo has origin top left
    end)
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

  # TODO so far we're pretty fast so we should be able to write this
  # without def_c, just native Elixir code. That'd require the stuff
  # below to move to individual Uderzo functions, of course.
  def_c draw_boid(x1, y1, x2, y2, x3, y3) do
    cdecl double: [x1, y1, x2, y2, x3, y3]

    nvgBeginPath(vg)
    nvgMoveTo(vg, x1, y1)
    nvgLineTo(vg, x2, y2)
    nvgLineTo(vg, x3, y3)
    nvgLineTo(vg, x1, y1)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 192))
    nvgFill(vg)
	  nvgStrokeColor(vg, nvgRGBA(0, 0, 0, 224))
	  nvgStroke(vg)
  end
end
