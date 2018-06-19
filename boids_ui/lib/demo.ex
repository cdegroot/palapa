defmodule Demo do
  @moduledoc """
  Run the Thermostat UI in Demo mode.
  """
  import Uderzo.Bindings
  require Logger

  def run do
    uderzo_init(self())
    # Toss 50 random boids on the screen
    boids = Enum.map(1..50, fn _ -> {:rand.normal() * 500, :rand.normal() * 500, :rand.normal()} end)
    receive do
      _msg ->
        glfw_create_window(800, 600, "Uderzo Boids", self())
        receive do
          {:glfw_create_window_result, window} ->
            render_loop(window, 0, boids)
            |> IO.inspect
            glfw_destroy_window(window)
          msg ->
            IO.puts("Received unknown message #{inspect msg}")
        end
    end
  end

  defp render_loop(window, frame, boids) do
    if rem(frame, 100) == 0 do
      Logger.info("Render frame #{frame}")
    end
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, _mx, _my, win_width, win_height} ->
        Enum.each(boids, fn {x, y, direction} ->
          BoidsUi.render(win_width, win_height, x, y, direction)
        end)
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            #Process.sleep(1) # Sort of limit frame rate
            render_loop(window, frame + 1, Enum.map(boids, fn {x, y, direction} ->
                  update_state(win_width, win_height, x, y, direction)
                end))
        end
    end
  end

  def update_state(width, height, x, y, direction) do
    dx = 1 * :math.cos(direction)
    dy = 1 * :math.sin(direction)
    {new_x, new_y} = {bound(width, x + dx), bound(height, y + dy)}
    new_state = {new_x, new_y, direction + 0.001}
    #IO.puts("(#{x}, #{y}, #{direction}) -> (#{dx}, #{dy}) -> #{inspect new_state}")
    new_state
  end

  def bound(bounds, value) do
    cond do
      value < 0 -> value + bounds
      value > bounds -> value - bounds
      value -> value
    end
  end

end
