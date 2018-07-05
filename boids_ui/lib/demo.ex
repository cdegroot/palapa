defmodule Demo do
  @moduledoc """
  Run the Boids model as a demo.

  The Boids model runs at its own time, so we define our FPS rate here and make
  sure that we - as much as possible - only call our frame rendering code once every
  frame.
  """

  @fps 50
  use Uderzo.GenRenderer

  def run do
    {:ok, boids} = Boids.start_link()
    Uderzo.GenRenderer.start_link(__MODULE__, "Uderzo Boids", 800, 600, @fps, boids)
    Process.sleep(:infinity)
  end

  def init_renderer(boids) do
    {:ok, boids}
  end

  def render_frame(win_width, win_height, _mx, _my, boids) do
    BoidsUi.paint_background(win_width, win_height)
    Enum.each(Boids.get_all(boids), fn {x, y, v} ->
      BoidsUi.render(win_width, win_height, x, y, v)
    end)
    {:ok, boids}
  end
end
