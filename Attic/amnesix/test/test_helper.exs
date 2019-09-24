ExUnit.start()

defmodule CapturingGenServer do
  @moduledoc """
  A GenServer that just captures messages for when you want to
  test simple interactions.

  I'm not sure this is a good idea.
  """
  import ExUnit.Assertions
  require Logger

  defmodule State do
    defstruct [:caps, :ans]
  end

  def start_link(call_answer \\ []) do
    GenServer.start_link(__MODULE__, call_answer)
  end

  # API

  def assert_received(pid, kind, msg) do
    assert Enum.member?(get(pid, kind), msg)
  end

  def get(pid, kind) do
    pid
    |> GenServer.call({:get, kind})
    |> Enum.reverse
  end

  # Server implementation

  def init(call_answer) do
    {:ok, %State{caps: %{}, ans: call_answer}}
  end

  def handle_call({:get, kind}, _from, state) do
    {:reply, Map.get(state.caps, kind, []), state}
  end

  def handle_call(msg, _from, state) do
    {:reply, state.ans, push(state, :call, msg)}
  end

  def handle_cast(msg, state) do
    {:noreply, push(state, :cast, msg)}
  end

  def handle_info(msg, state) do
    {:noreply, push(state, :info, msg)}
  end

  defp push(state, kind, msg) do
    %State{state | caps: Map.update(state.caps, kind, [msg], fn(msgs) -> [msg|msgs] end)}
  end
end
