defmodule Erix.Server.PersistentState do
  @moduledoc """
  Management of the server state parts that is required to
  be persistent: current term, candidates voted for, and the log.

  Most of its methods send and receive `Erix.Server.State` structures,
  but this module only promises to ever use `persistent_state`. Sending
  state instead of persistent state just takes away some of the burden of
  managing this sub state from the main code. In fact, most of this code
  is just glue code that forwards call to the actual persistence engine,
  has some sugar methods, and some sensible defaults (like setting up
  in memory persistence if nothing else is passed in).
  """
  require Logger
  import Simpler.TestSupport

  defstruct mod: nil, pid: nil

  # TODO cache frequently accessed stuff? Or we just don't care?

  @doc """
  Read state from persistence
  """
  def initialize_persistence(nil, _state) do
    # TODO setup in memory engine?
    raise "Please pass in a persistence module"
  end
  def initialize_persistence(persistence_ref = {mod, pid}, state) do
    set_persister(persistence_ref, state)
  end

  deft set_persister({mod, pid} = _persistence_ref, state) do
    %Erix.Server.State{state |
                       persistent_state: %__MODULE__{mod: mod, pid: pid}}
  end

  # Current term functions

  @doc "Returns the current term of the state"
  def current_term(state) do
    mod(state).current_term(pid(state)) || 0
  end

  @doc "Update the current term in the state"
  def set_current_term(new_term, state) do
    mod(state).set_current_term(pid(state), new_term)
    state
  end

  # Voted for functions

  @doc "Returns the current voted_for value"
  def voted_for(state) do
    mod(state).voted_for(pid(state))
  end

  @doc "Sets the current voted_for value"
  def set_voted_for(peer, state) do
    mod(state).set_voted_for(pid(state), peer)
    state
  end

  # Log funcions

  @doc "Returns the log entry at the (1-based) index, or {0, nil}"
  def log_at(pos, state) do
    mod(state).log_at(pid(state), pos) || {0, nil}
  end

  @doc "Returns the log starting at the (1-based) offset, or []"
  def log_from(pos, state) do
    mod(state).log_from(pid(state), pos) || []
  end

  @doc "Returns the last offset of the log, or 0"
  def log_last_offset(state) do
    mod(state).log_last_offset(pid(state)) || 0
  end

  @doc """
  Replaces the log from the indicated (1-based) position with the entries.
  `log_position` may refer to a new or existing position, the latter effectively
  overwriting the log to make it match the leader's log.
  """
  def append_entries_to_log(log_position, new_entries, state) do
    mod(state).append_entries_to_log(pid(state), log_position, new_entries)
    state
  end

  # Private functions

  defp persistent_state(state) do
    state.persistent_state || %__MODULE__{}
  end

  defp mod(state), do: persistent_state(state).mod
  defp pid(state), do: persistent_state(state).pid
end
