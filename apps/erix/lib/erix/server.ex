defmodule Erix.Server do
  @moduledoc """
  A Raft server.
  """
  use GenServer
  use Erix.Constants
  import Simpler.TestSupport
  require Logger

  @type log_entry :: {term :: integer, entry :: any}
  @type peer_ref :: {module :: atom, pid :: pid}

  defmodule State do
    defstruct state: nil,
      persistence_mod: nil, persistence_pid: nil,
      current_term: 0,
      peers: [],
      voted_for: nil,
      log: [], # TODO smarter data structure
      commit_index: 0, last_applied: 0,
      current_time: -1,
      last_heartbeat_seen: -1,
      current_state_data: nil
  end

  def start_link(persistence_ref = {_mod, _pid}) do
    GenServer.start_link(__MODULE__, {persistence_ref})
  end

  @doc "Given a state tag, return the module implementing it"
  def state_module(state_tag) do
    Module.concat(__MODULE__, Macro.camelize(Atom.to_string(state_tag)))
  end

  @doc "Execute a tick."
  def tick(pid) do
    GenServer.cast(pid, :tick)
  end

  @doc "Add a peer server"
  def add_peer(pid, peer_pid) do
    GenServer.cast(pid, {:add_peer, peer_pid})
  end

  # TODO rename request vote to request request vote or something? At least some
  # naming consistency for all of these.

  @doc "Receive a RequestVote RPC"
  def request_vote(pid, term, candidate_id, last_log_index, last_log_term) do
    GenServer.cast(pid, {:request_vote, term, candidate_id, last_log_index, last_log_term})
  end

  @doc "Reply on a RequestVote RPC"
  def vote_reply(pid, term, vote_granted) do
    GenServer.cast(pid, {:vote_reply, term, vote_granted})
  end

  @doc "Receive an AppendEntries RPC"
  def request_append_entries(pid, term, leader_id, prev_log_index, prev_log_term, entries, leader_commit) do
    GenServer.cast(pid, {:request_append_entries, term, leader_id, prev_log_index, prev_log_term,
                         entries, leader_commit})
  end

  # Mostly test helpers that dig around in state

  deft __fortest__getstate(pid) do
    GenServer.call(pid, :__fortest__getstate)
  end

  # Server implementation

  def init({_persistence_ref = {pmod, ppid}}) do
    initial_state = %State{state: :follower, persistence_mod: pmod, persistence_pid: ppid}
    state = read_from_persistence(initial_state)
    {:ok, state}
  end

  # Testing support stuff
  def handle_call(:__fortest__getstate, _from, state) do
    {:reply, state, state}
  end
  def handle_cast({:__fortest__setstate, state}, _state) do
    {:noreply, state}
  end

  # Most of the calls here are state-specific; they forward to the
  # corresponding state module and declare a @callback to implement.

  @callback tick(state :: %State{}) :: %State{}

  def handle_cast(:tick, state) do
    state = %{state | current_time: state.current_time + 1}
    mod = state_module(state.state)
    {:noreply, mod.tick(state)}
  end

  @callback add_peer(peer_id :: peer_ref, state :: %State{}) :: %State{}

  def handle_cast({:add_peer, peer_id}, state) do
    mod = state_module(state.state)
    {:noreply, mod.add_peer(peer_id, state)}
  end


  @callback request_vote(term :: integer, candidate_id :: peer_ref, last_log_index :: integer, last_log_term :: integer, state :: %State{}) :: %State{}

  def handle_cast({:request_vote, term, candidate_id, last_log_index, last_log_term}, state) do
    mod = state_module(state.state)
    {:noreply, mod.request_vote(term, candidate_id, last_log_index, last_log_term, state)}
  end

  @callback vote_reply(state :: %State{}) :: %State{}

  def handle_cast({:vote_reply, term, vote_granted}, state) do
    mod = state_module(state.state)
    {:noreply, mod.vote_reply(term, vote_granted, state)}
  end


  @callback request_append_entries(term :: integer, leader_id :: peer_ref, prev_log_index :: integer,
    prev_log_term :: integer, entries :: list(), leader_commit :: integer,
    state :: %State{}) :: %State{}

  def handle_cast({:request_append_entries, term, leader_id, prev_log_index, prev_log_term, entries, leader_commit}, state) do
    mod = state_module(state.state)
    {:noreply, mod.request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state)}
  end

  @type append_entries_reply :: {term :: integer, success :: boolean}

  # Helper stuff

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
