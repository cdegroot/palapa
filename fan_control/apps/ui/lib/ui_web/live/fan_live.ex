defmodule UiWeb.Live.FanLive do
  use Phoenix.LiveView

  require Logger

  def render(assigns) do
    ~L"""
    Current state: <%= @toggle %>
    <br/>
    <div phx-click="toggle">Toggle</div>
    """
  end

  def mount(session, socket) do
    Logger.debug("live mount, session: #{inspect session}, socket: #{inspect socket}")
    if connected?(socket), do: :timer.send_interval(1_000, self(), :update)
    {:ok, assign_toggle(socket)}
  end

  def handle_info(:update, socket) do
    {:noreply, assign_toggle(socket)}
  end

  def handle_event("toggle", _session, socket) do
    Control.toggle()
    {:noreply, assign_toggle(socket)}
  end

  defp assign_toggle(socket) do
    assign(socket, :toggle, Control.get_state())
  end
end
