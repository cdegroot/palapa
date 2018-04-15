defmodule Uderzo.GraphicsServerTest do
  use ExUnit.Case, async: true

  alias Uderzo.GraphicsServer
  alias Uderzo.Bindings

  test "Graphics server accepts commands" do
    GraphicsServer.send_commands(Uderzo.GraphicsServer,
      {:comment, "This is a comment we can ignore for testing and stuff"})
    GraphicsServer.send_commands(Uderzo.GraphicsServer,
      [{:window, 1000, 600, "Demo window"},
       {:on_frame, self()}])
    IO.puts("Sleeping a bit...")
    Process.sleep(1_000)
  end

  test "Bindings work" do
    Bindings.comment("Comment")
    Bindings.window(640, 480, "Another demo window")
    Bindings.on_frame(self())
    IO.puts("Sleeping a bit...")
    Process.sleep(1_000)
  end
end
