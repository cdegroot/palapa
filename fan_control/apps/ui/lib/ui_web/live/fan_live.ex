defmodule UiWeb.Live.FanLive do
  use Phoenix.LiveView

  require Logger

  def render(assigns) do
    ~L"""
    Current state: <%= @toggle %>
    """
  end

  def mount(stuff, socket) do
    Logger.info("live mount, #{inspect stuff}, #{inspect socket}")
    {:ok, assign(socket, :toggle, Control.get_state)}
  end
end
