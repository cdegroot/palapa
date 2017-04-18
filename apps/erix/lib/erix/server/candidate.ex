defmodule Erix.Server.Candidate do
  @moduledoc """
  Implementation of a server's candidate state
  """
  require Logger
  use Erix.Constants
  import Erix.Server.PersistentState

  @behaviour Erix.Server

  defmodule State do
    defstruct election_start: 0,
      vote_count: 0
  end

  def tick(state) do
    if state.current_time - state.current_state_data.election_start > @election_timeout_ticks do
      # Trigger a new election by transitioning again into candidate state
      transition_from(:candidate, state, "election timeout")
    else
      state
    end
  end

  defdelegate add_peer(peer_id, state), to: Erix.Server.Common

  @doc "Become a candidate"
  def transition_from(old, state, reason \\ "unknown") do
    Logger.info("#{inspect self()} transition from #{old} to candidate: #{reason}")
    if length(state.peers) == 0 do
      # Short-circuit into leader if we don't have any peers
      mod = Erix.Server.state_module(:leader)
      mod.transition_from(:candidate, state, "no peers")
    else
      # Nope, we need real elections
      candidate_state = %State{election_start: state.current_time, vote_count: 1}
      state = %{state | state: :candidate,
                current_state_data: candidate_state}
      current_term = current_term(state) + 1
      set_current_term(current_term, state)
      last_log_index = log_last_offset(state)
      {last_log_term, _} = log_at(last_log_index, state)
      state.peers
      |> Enum.map(fn({mod, pid}) ->
        mod.request_vote(pid, current_term, {Erix.Server, self()}, last_log_index, last_log_term)
      end)
      state
    end
  end

  def request_vote(term, candidate_id, last_log_index, last_log_term, state) do
    if term > current_term(state) do
      mod = Erix.Server.state_module(:follower)
      state = set_current_term(term, state)
      mod.transition_from(state.state, state, "newer term seen in request_vote")
    else
      state
    end
  end

  def vote_reply(term, vote_granted, state) do
    if term > current_term(state) do
      mod = Erix.Server.state_module(:follower)
      state = set_current_term(term, state)
      mod.transition_from(state.state, state, "newer term seen in vote_reply")
    else
      if vote_granted do
        # We always vote for ourselves as a candidate, so add one to both.
        vote_count = state.current_state_data.vote_count + 1
        peer_count = length(state.peers) + 1
        if vote_count / peer_count > 0.5 do
          mod = Erix.Server.state_module(:leader)
          mod.transition_from(:candidate, state, "got quorum votes (#{inspect vote_count}/#{inspect peer_count})")
        else
          %{state | current_state_data: %{state.current_state_data | vote_count: vote_count}}
        end
      else
        state
      end
    end
  end

  @doc "Received an AppendEntries RPC. This immediately triggers follower behaviour"
  def request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state) do
    mod = Erix.Server.state_module(:follower)
    state = mod.transition_from(:candidate, state, "candidate got request_append_entries")
    # Let the follower state handle the actual call
    mod.request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state)
  end

  defdelegate append_entries_reply(from, term, reply, state), to: Erix.Server.Common
end
