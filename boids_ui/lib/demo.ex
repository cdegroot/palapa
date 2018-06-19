defmodule Demo do
  @moduledoc """
  Run the Thermostat UI in Demo mode.
  """
  import Uderzo.Bindings
  require Logger

  def run do
    uderzo_init(self())
    receive do
      _msg ->
        glfw_create_window(800, 600, "Uderzo Boids", self())
        receive do
          {:glfw_create_window_result, window} ->
            render_loop(window, 50.0, 50.0, 0.2)
            |> IO.inspect
            glfw_destroy_window(window)
          msg ->
            IO.puts("Received unknown message #{inspect msg}")
        end
    end
  end

  defp render_loop(window, x, y, direction) do
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, _mx, _my, win_width, win_height} ->
        BoidsUi.render(win_width, win_height, x, y, direction)
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            Process.sleep(5) # Sort of limit frame rate
            {x, y, direction} = update_state(win_width, win_height, x, y, direction)
            render_loop(window, x, y, direction)
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
