defmodule Erix.Server.Candidate do
  @moduledoc """
  Implementation of a server's candidate state
  """
  require Logger
  use Erix.Constants
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
    candidate_state = %State{election_start: state.current_time, vote_count: 1}
    # TODO persist current_term
    state = %{state | state: :candidate,
              current_term: state.current_term + 1,
              current_state_data: candidate_state}
    state.peers
    |> Enum.map(fn({mod, pid}) ->
      # TODO: the fourth argument is incorrect.
      mod.request_vote(pid, state.current_term, self(), length(state.log), 0)
    end)
    state
  end

  @doc "Receive a reply to a vote"
  def vote_reply(term, vote_granted, state) do
    vote_count = state.current_state_data.vote_count + 1
    peer_count = length(state.peers)
    if vote_count / peer_count > 0.5 do
      mod = Erix.Server.state_module(:leader)
      mod.transition_from(:candidate, state)
    else
      %{state | current_state_data: %{state.current_state_data | vote_count: vote_count}}
    end
  end

  @doc "Received an AppendEntries RPC. This immediatel triggers follower behaviour"
  def request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state) do
    mod = Erix.Server.state_module(:follower)
    state = mod.transition_from(:candidate, state)
    # Let the follower state handle the actual call
    mod.request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state)
  end

  defdelegate request_vote(pid, term, candidate_id, last_log_index, last_log_term), to: Erix.Server.Common
end
