defmodule Uderzo.GraphicsServerTest do
  use ExUnit.Case, async: true

  import Uderzo.Bindings

  test "Bindings work for a basic demo" do
    comment("Comment")
    glfw_create_window(640, 480, "Another demo window", self())
    receive do
      {:glfw_create_window_result, window} ->
        IO.puts("Window created, handle is #{inspect window}")
        paint_a_frame(window)
        Process.sleep(1_000)
        glfw_destroy_window(window)
      msg ->
        IO.puts("Received message #{inspect msg}")
    end
    Process.sleep(1_000)
  end

  defp paint_a_frame(window) do
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, mx, my, win_width, win_height} ->
        t = :erlang.system_time(:nanosecond) / 1000000000.0
	      demo_render(mx, my, win_width, win_height, t)
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            IO.puts("Frame complete")
        end
    end
  end
end
