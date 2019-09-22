defmodule UiWeb.Live.FanLive do
  use Phoenix.LiveView

  require Logger

  @translate %{false: "off", true: "on"}

  def render(assigns) do
    Logger.debug("Render, assigns=#{inspect assigns}")
    ~L"""
    <div style="font-size: 20px; text-align: center">Current furnace fan state: <%= @toggle %></div>
    <br/>
    <div phx-click="toggle" style="font-size: 60px; border: 2px solid; text-align: center">Switch <%= @switch %> </div>
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
    socket
    |> assign(:toggle, Map.get(@translate, Control.get_state()))
    |> assign(:switch, Map.get(@translate, not Control.get_state()))
  end
end
