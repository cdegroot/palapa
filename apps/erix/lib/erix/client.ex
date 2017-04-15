defmodule Erix.Client do
  @moduledoc """
  Representation of the client. It sends commands (and thus receives
  command completion), and it gets command to apply to the state
  machine (whatever that may mean to the client).

  There's a lot of TDB in here, but the idea is to keep a clean separation
  between the core Raft protocol (the log management) and interpretation
  of what's in the log (commands, state machine management).
  """

  @doc """
  Indicates that a client command succesfully copmleted.
  """
  @callback command_completed(client_pid :: pid, command_id :: integer) :: :ok

  @doc """
  Indicates that a client command should be applied to the state machine
  """
  @callback apply_command(client_pid :: pid, command :: any) :: :ok

end
