defmodule Demo do
  @moduledoc """
  Run the Boids model as a demo.

  The Boids model runs at its own time, so we define our FPS rate here and make
  sure that we - as much as possible - only call our frame rendering code once every
  frame.
  """

  @fps 60
  use Uderzo.GenRenderer

  def run do
    Boids.start_link()
    Uderzo.GenRenderer.start_link(__MODULE__, "Uderzo Boids", 800, 600, @fps, [])
    Process.sleep(:infinity)
  end

  def render_frame(win_width, win_height, _mx, _my, state) do
    Enum.each(Boids.get_boids(), fn {x, y, direction} ->
      BoidsUi.render(win_width, win_height, x, y, direction)
    end)
    {:ok, state}
  end
end
