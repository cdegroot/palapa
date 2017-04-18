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
      transition_from(:candidate, state)
    else
      state
    end
  end

  defdelegate add_peer(peer_id, state), to: Erix.Server.Common

  @doc "Become a candidate"
  def transition_from(_, state) do
    if length(state.peers) == 0 do
      # Short-circuit into leader if we don't have any peers
      mod = Erix.Server.state_module(:leader)
      mod.transition_from(:candidate, state)
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

  def vote_reply(term, vote_granted, state) do
    if term > current_term(state) do
      mod = Erix.Server.state_module(:follower)
      state = set_current_term(term, state)
      mod.transition_from(state.state, state)
    else
      # TODO just noticed we never looked at vote_granted, check test coverage
      if vote_granted do
        vote_count = state.current_state_data.vote_count + 1
        peer_count = length(state.peers)
        if vote_count / peer_count > 0.5 do
          mod = Erix.Server.state_module(:leader)
          mod.transition_from(:candidate, state)
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
    state = mod.transition_from(:candidate, state)
    # Let the follower state handle the actual call
    mod.request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state)
  end

  defdelegate append_entries_reply(from, term, reply, state), to: Erix.Server.Common

  defdelegate request_vote(pid, term, candidate_id, last_log_index, last_log_term), to: Erix.Server.Common
end
