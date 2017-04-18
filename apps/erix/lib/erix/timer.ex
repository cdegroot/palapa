defmodule Erix.Timer do
  @moduledoc """
  A simple timer module that sends the ticks to the Server. It uses a plm.25% random jitter to
  help Raft along a bit.
  """
  use GenServer

  def start_link(tick_time, fun) do
    GenServer.start_link(__MODULE__, {tick_time, fun})
  end
  def init({tick_time, fun}) do
    offset = Integer.floor_div(tick_time, 4)
    jitter = offset * 2
    state = {tick_time, offset, jitter, fun}
    start_timer(state)
    {:ok, state}
  end
  def handle_info(:tick, state = {_tick, _offset, _jitter, fun}) do
    fun.()
    start_timer(state)
    {:noreply, state}
  end
  defp start_timer({tick_time, offset, jitter, _fun}) do
    pause = tick_time - offset + :rand.uniform(jitter)
    Process.send_after(self(), :tick, pause)
  end
end
