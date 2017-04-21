defmodule Erix.Client do
  @moduledoc """
  Representation of the client. It sends commands (and thus receives
  command completion), and it gets command to apply to the state
  machine (whatever that may mean to the client).

  There's a lot of TDB in here, but the idea is to keep a clean separation
  between the core Raft protocol (the log management) and interpretation
  of what's in the log (commands, state machine management). The client
  also keeps the current snapshot of the state, which is useful if later
  on we implement snapshotting. As such, the client is an integral part
  of the protocol.
  """
  use GenServer

  defmodule State do
    defstruct node_name: nil, data: %{}, counter: 0, to_complete: %{}
  end

  @doc """
  Indicates that a client command succesfully completed. Callback from the node
  when command got committed.
  """
  def command_completed(pid, command_id) do
    GenServer.cast(pid, {:command_completed, command_id})
  end

  def start_link(node_name) do
    GenServer.start_link(__MODULE__, node_name, name: Erix.Node.client_name(node_name))
  end

  @doc "Return the number of data items"
  def count(pid), do: GenServer.call(pid, :count)

  @doc "Write data"
  def put(pid, key, value), do: GenServer.call(pid, {:put, key, value})

  # Server implementation

  def init(node_name) do
    {:ok, %State{node_name: node_name}}
  end

  def handle_call(:count, _from, state) do
    {:reply, map_size(state.data), state}
  end

  def handle_call({:put, key, value}, from, state) do
    counter = state.counter + 1
    self_ref = {Erix.Client, self()}
    case Erix.Server.client_command(state.node_name, self_ref, counter, {key, value}) do
      reply = {:error, reason} ->
        {:reply, reply, %{state | counter: counter}}
      :ok ->
        to_complete = Map.put(state.to_complete, counter, {from, key, value})
        {:noreply, %{state | counter: counter, to_complete: to_complete}}
    end
  end

  def handle_cast({:command_completed, command_id}, state) do
    # Command has been committed, so we can apply it to our data
    {{from, key, value}, to_complete} = Map.pop(state.to_complete, command_id)
    data = Map.put(state.data, key, value)
    GenServer.reply(from, :ok)
    {:noreply, %State{state | data: data, to_complete: to_complete}}
  end
end
