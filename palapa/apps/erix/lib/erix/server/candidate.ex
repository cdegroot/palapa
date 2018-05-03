defmodule Erix.Server.Candidate do
  @moduledoc """
  Implementation of a server's candidate state
  """
  require Logger
  use Erix.Constants
  import Erix.Server.PersistentState
  alias Erix.Server.Peer

  @behaviour Erix.Server

  defmodule State do
    defstruct election_start: 0,
      vote_count: 0
  end

  def tick(state) do
    if state.current_time - state.current_state_data.election_start > @election_timeout_ticks do
      # Trigger a new election by transitioning again into candidate state
      transition_to(:candidate, state, "election timeout")
    else
      state
    end
  end

  defdelegate add_peer(peer_id, state), to: Erix.Server.Common

  def client_command(_client_id, _command_id, _terms_to_log, _state) do
    {:error, :leader_not_yet_known}
  end

  @doc "Become a candidate"
  def transition_from(old, state, reason \\ "unknown") do
    Logger.info("#{inspect self()} transition from #{old} to candidate: #{reason}")
    if Peer.peerless?(state) do
      # Short-circuit into leader if we don't have any peers.
      transition_to(:leader, state, "no peers")
    else
      # Nope, we need real elections
      candidate_state = %State{election_start: state.current_time, vote_count: 1}
      state = %{state | state: :candidate,
                current_state_data: candidate_state}
      current_term = current_term(state) + 1
      set_current_term(current_term, state)
      last_log_index = log_last_offset(state)
      {last_log_term, _} = log_at(last_log_index, state)
      Peer.map(state, fn(peer) ->
        Peer.request_vote(peer, current_term, last_log_index,
          last_log_term, state)
      end)
      state
    end
  end

  defp transition_to(state_atom, state, reason) do
    mod = Erix.Server.state_module(state_atom)
    mod.transition_from(:candidate, state, reason)
  end


  def request_vote(term, _candidate, _last_log_index, _last_log_term, state) do
    if term > current_term(state) do
      state = set_current_term(term, state)
      transition_to(:follower, state, "newer term seen in request_vote")
    else
      state
    end
  end

  def vote_reply(term, vote_granted, state) do
    if term > current_term(state) do
      state = set_current_term(term, state)
      transition_to(:follower, state, "newer term seen in vote_reply")
    else
      if vote_granted do
        # We always vote for ourselves as a candidate, so add one to both.
        vote_count = state.current_state_data.vote_count + 1
        peer_count = Peer.count(state) + 1
        if vote_count / peer_count > 0.5 do
          transition_to(:leader, state,
            "got quorum votes (#{inspect vote_count}/#{inspect peer_count})")
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
    state = transition_to(:follower, state, "candidate got request_append_entries")
    # Let the follower state handle the actual call
    Erix.Server.Follower.request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state)
  end

  defdelegate append_entries_reply(from, term, reply, state), to: Erix.Server.Common
end
