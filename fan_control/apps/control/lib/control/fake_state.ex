defmodule Control.FakeState do
  require Logger
  use Agent

  def start_link(_initial) do
    Agent.start_link(fn -> false end, name: __MODULE__)
  end

  def get_state do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def toggle do
    Agent.update(__MODULE__, fn state -> not state end)
  end
end
