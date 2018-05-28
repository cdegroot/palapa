defmodule Erix.Server.PersistentState do
  @moduledoc """
  Management of the server state parts that is required to
  be persistent: current term, candidates voted for, and the log.

  Most of its methods send and receive `Erix.Server.State` structures,
  but this module only promises to ever use `persistent_state`. Sending
  state instead of persistent state just takes away some of the burden of
  managing this sub state from the main code. In fact, most of this code
  is just glue code that forwards call to the actual persistence engine,
  has some sugar methods, and some sensible defaults (like converting
  nil replies from the persistence layer into something the rest of the
  code can work with).
  """
  require Logger
  import Simpler.TestSupport

  defstruct mod: nil, pid: nil

  @doc """
  Read state from persistence
  """
  def initialize_persistence(nil, _state) do
    raise "Please pass in a persistence module"
  end
  def initialize_persistence(persistence_ref, state) do
    set_persister(persistence_ref, state)
  end

  defp set_persister({mod, pid} = _persistence_ref, state) do
    %Erix.Server.State{state |
                       persistent_state: %__MODULE__{mod: mod, pid: pid}}
  end

  deft _set_persister(persistence_ref, state) do
    set_persister(persistence_ref, state)
  end

  # Current term functions

  @callback current_term(pid :: pid) :: integer

  @doc "Returns the current term of the state"
  def current_term(state) do
    mod(state).current_term(pid(state)) || 0
  end

  @callback set_current_term(pid :: pid, term :: integer) :: any

  @doc "Update the current term in the state"
  def set_current_term(new_term, state) do
    mod(state).set_current_term(pid(state), new_term)
    state
  end

  # Voted for functions

  @callback voted_for(pid :: pid) :: Erix.Server.peer_ref

  @doc "Returns the current voted_for value"
  def voted_for(state) do
    mod(state).voted_for(pid(state))
  end

  @callback set_voted_for(pid :: pid, peer :: Erix.Server.peer_ref) :: any

  @doc "Sets the current voted_for value"
  def set_voted_for(peer, state) do
    mod(state).set_voted_for(pid(state), peer)
    state
  end

  # Log funcions

  @callback log_at(pid :: pid, pos :: integer) :: Erix.Server.log_entry

  @doc "Returns the log entry at the (1-based) index, or {0, nil}"
  def log_at(pos, state) do
    mod(state).log_at(pid(state), pos) || {0, nil}
  end

  @callback log_from(pid :: pid, pos :: integer) :: list(Erix.Server.log_entry)

  @doc "Returns the log starting at the (1-based) offset, or []"
  def log_from(pos, state) do
    mod(state).log_from(pid(state), pos) || []
  end

  @callback log_last_offset(pid :: pid) :: integer

  @doc "Returns the last offset of the log, or 0"
  def log_last_offset(state) do
    mod(state).log_last_offset(pid(state)) || 0
  end

  @callback append_entries_to_log(pid :: pid, pos :: integer, entries :: list(Erix.Server.log_entry)) :: any

  @doc """
  Replaces the log from the indicated (1-based) position with the entries.
  `log_position` may refer to a new or existing position, the latter effectively
  overwriting the log to make it match the leader's log.
  """
  def append_entries_to_log(log_position, new_entries, state) do
    mod(state).append_entries_to_log(pid(state), log_position, new_entries)
    state
  end

  @callback node_uuid(pid :: pid) :: binary

  @doc "Returns the uuid of the node"
  def node_uuid(state) do
    mod(state).node_uuid(pid(state))
  end

  @callback set_node_uuid(pid :: pid, uuid :: binary) :: any

  @doc "Sets the uuid of the node"
  def set_node_uuid(uuid, state) do
    mod(state).set_node_uuid(pid(state), uuid)
  end

  # Private functions

  defp persistent_state(state) do
    state.persistent_state || %__MODULE__{}
  end

  defp mod(state), do: persistent_state(state).mod
  defp pid(state), do: persistent_state(state).pid
end
