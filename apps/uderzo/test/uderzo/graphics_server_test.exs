defmodule Uderzo.GraphicsServerTest do
  use ExUnit.Case, async: true

  alias Uderzo.GraphicsServer
  alias Uderzo.Bindings

  test "Bindings work" do
    Bindings.comment("Comment")
    Bindings.glfw_create_window(640, 480, "Another demo window", self())
    receive do
      {:ok, window} ->
        IO.puts("Window created, handle is #{inspect window}")
        IO.puts("Sleeping a bit...")
        Process.sleep(1_000)
        Bindings.glfw_destroy_window(window)
      msg ->
        IO.puts("Received message #{inspect msg}")
    end
    IO.puts("Sleeping a bit...")
    Process.sleep(1_000)
  end
end
