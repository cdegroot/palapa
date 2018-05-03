defmodule UiWeb.ThermostatChannel do
  use UiWeb, :channel
  require Logger

  def join("thermostat", _payload, socket) do
    Logger.debug("Someone joined thermostat #{inspect socket}")
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    tick(socket, 0)
    {:noreply, socket}
  end

  def tick(socket, n) do
    Task.start(fn ->
      Process.sleep(5000)
      broadcast! socket, "new_msg", %{"outside_temp" => n}
      tick(socket, n + 1)
    end)
  end
end
