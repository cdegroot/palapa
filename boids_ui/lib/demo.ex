defmodule Demo do
  @moduledoc """
  Run the Boids model as a demo.

  The Boids model runs at its own time, so we define our FPS rate here and make
  sure that we - as much as possible - only call our frame rendering code once every
  frame.

  TODO: it's time to abstract this stuff in Uderzo. `gen_renderer` or something like that.
  """
  import Uderzo.Bindings
  require Logger

  # Frame limiting stuff.
  @fps 50
  @ms_between_frames div(1_000, 50)
  def cur_time, do: :erlang.monotonic_time(:millisecond)
  def next_target_time, do: cur_time() + @ms_between_frames
  # Heuristics - we seem to be one ms slow...
  def nap_time(ntt), do: max(0, ntt - cur_time() - 1)

  def run do
    Boids.start_link()
    uderzo_init(self())
    receive do
      _msg ->
        glfw_create_window(800, 600, "Uderzo Boids", self())
        receive do
          {:glfw_create_window_result, window} ->
            render_loop(window, 0)
            |> IO.inspect
            glfw_destroy_window(window)
          msg ->
            IO.puts("Received unknown message #{inspect msg}")
        end
    end
  end

  defp render_loop(window, frame) do
    ntt = next_target_time()
    if rem(frame, @fps) == 0 do
      # Check @fps precision the simple way
      Logger.info("Render frame #{frame}")
    end
    # Render
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, _mx, _my, win_width, win_height} ->
        Enum.each(Boids.get_boids(), fn {x, y, direction} ->
          BoidsUi.render(win_width, win_height, x, y, direction)
        end)
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            Process.send_after(self(), :render_next, nap_time(ntt))
            receive do
              :render_next ->
                render_loop(window, frame + 1)
            end
        end
    end
  end
end
