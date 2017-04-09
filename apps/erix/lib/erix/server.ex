defmodule Erix.Server do
  @moduledoc """
  A Raft server.
  """
  use GenServer
  use Erix.Constants
  import Simpler.TestSupport
  require Logger

  defmodule Candidate do
    defstruct election_start: 0,
      votes: []
  end
  defmodule State do
    defstruct state: nil,
      persistence_mod: nil, persistence_pid: nil,
      current_term: 0,
      voted_for: nil,
      log: [],
      current_time: -1,
      last_heartbeat_seen: -1,
      current_state_data: nil
  end

  def start_link(persistence_ref = {_mod, _pid}) do
    GenServer.start_link(__MODULE__, {persistence_ref})
  end

  def tick(pid) do
    GenServer.cast(pid, :tick)
  end

  # Mostly test helpers that dig around in state

  def current_term(_server) do
    0
  end

  def voted_for(_server) do
    nil
  end

  def log(_server) do
    []
  end

  def commit_index(_server) do
    0
  end

  def committed(_server) do
    0
  end

  def last_applied(_server) do
    0
  end

  deft __fortest__getstate(pid) do
    GenServer.call(pid, :__fortest__getstate)
  end
  deft __fortest__setstate(pid, state) do
    GenServer.cast(pid, {:__fortest__setstate, state})
  end

  # Server implementation

  def init({_persistence_ref = {pmod, ppid}}) do
    initial_state = %State{state: :follower, persistence_mod: pmod, persistence_pid: ppid}
    state = read_from_persistence(initial_state)
    {:ok, state}
  end

  def handle_call(:__fortest__getstate, _from, state) do
    {:reply, state, state}
  end
  def handle_cast({:__fortest__setstate, state}, _state) do
    {:noreply, state}
  end

  def handle_cast(:tick, state) do
    state = %{state | current_time: state.current_time + 1}
    state = handle_tick(state.state, state)
    {:noreply, state}
  end

  defp handle_tick(:follower, state) do
    Logger.debug("tick time=#{state.current_time} lhbs=#{state.last_heartbeat_seen}")
    if state.current_time - state.last_heartbeat_seen > @election_timeout_ticks do
      transition(:follower, :candidate, state)
    else
      state
    end
  end

  deft transition(:follower, :candidate, state) do
    candidate_state = %Candidate{election_start: state.current_time, votes: [self()]}
    state = %{state | state: :candidate,
      current_term: state.current_term + 1,
      current_state_data: candidate_state}
  end

  defp read_from_persistence(state) do
    if state.persistence_mod != nil do
      current_term = state.persistence_mod.fetch_current_term(state.persistence_pid)
      voted_for = state.persistence_mod.fetch_voted_for(state.persistence_pid)
      log = state.persistence_mod.fetch_log(state.persistence_pid)
      %{state | current_term: current_term, voted_for: voted_for, log: log}
    else
      Logger.warn("Initializing server without persistence module!")
      state
    end
  end
end
