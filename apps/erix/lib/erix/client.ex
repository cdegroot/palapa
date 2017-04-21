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
    defstruct node_name: nil
  end

  @doc """
  Indicates that a client command succesfully copmleted.
  """
  @callback command_completed(client_pid :: pid, command_id :: integer) :: :ok

  def start_link(node_name) do
    GenServer.start_link(__MODULE__, node_name, name: Erix.Node.client_name(node_name))
  end

  # Server implementation

  def init(node_name) do
    {:ok, %State{node_name: node_name}}
  end
end
