defmodule Uderzo.GraphicsServerTest do
  use ExUnit.Case, async: true

  import Uderzo.Bindings

  test "Bindings work for a basic demo" do
    comment("Comment")
    glfw_create_window(640, 480, "Another demo window", self())
    receive do
      {:glfw_create_window_result, window} ->
        IO.puts("Window created, handle is #{inspect window}")
        IO.puts("Sleeping a bit...")
        paint_a_frame(window)
        Process.sleep(1_000)
        glfw_destroy_window(window)
      msg ->
        IO.puts("Received message #{inspect msg}")
    end
    IO.puts("Sleeping a bit...")
    Process.sleep(1_000)
  end

  defp paint_a_frame(window) do
    IO.puts "paint by numbers"
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, mx, my, win_width, win_height} ->
        # TODO return floats above so we don't have to convert all the time
        IO.puts "mx, my: #{mx}, #{my}"
        IO.puts "ww, wh: #{win_width}, #{win_height}"
        t = :erlang.system_time(:nanosecond) / 1000000000.0
	      demo_render(mx * 1.0, my * 1.0, win_width * 1.0, win_height * 1.0, t)
        draw_eyes((win_width * 1.0) - 250, 50.0, 150.0, 100.0, mx * 1.0, my * 1.0, t)
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            IO.puts("Frame complete")
        end
    end
  end
end
