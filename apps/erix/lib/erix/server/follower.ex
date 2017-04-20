defmodule Erix.Server.Follower do
  @moduledoc """
  Implementation of Follower state
  """
  require Logger
  use Erix.Constants
  import Erix.Server.PersistentState
  alias Erix.Server.Peer

  defmodule State do
    defstruct leader: nil
  end

  @behaviour Erix.Server

  def tick(state) do
    if state.current_time - state.last_heartbeat_seen > @heartbeat_timeout_ticks do
      Logger.debug("#{inspect self()} heartbeat timeout #{state.current_time} last #{state.last_heartbeat_seen}")
      transition_to(:candidate, state, "heartbeat timeout")
    else
      state
    end
  end

  def transition_from(old, state, reason \\ "unknown") do
    Logger.info("#{inspect self()} transition from #{old} to follower: #{reason}")
    %{state | state: :follower, current_state_data: %State{}, last_heartbeat_seen: state.current_time}
  end

  defp transition_to(state_atom, state, reason) do
    mod = Erix.Server.state_module(state_atom)
    mod.transition_from(:follower, state, reason)
  end

  defdelegate add_peer(peer_id, state), to: Erix.Server.Common

  def request_append_entries(term, leader, prev_log_index, prev_log_term, entries, leader_commit, state) do
    current_term = current_term(state)
    state = %{state | current_state_data: %{state.current_state_data | leader: leader}}
    state = if term < current_term do
      # Bad term, send the current term back
      Peer.append_entries_reply(leader, current_term, false, state)
      state
    else
      {reply, state} = case log_at(prev_log_index, state) do
        nil ->
          {false, state}
        {pl_term, _} when pl_term != prev_log_term ->
          {false, state}
        _ ->
          state = append_entries_to_log(prev_log_index + 1, entries, state)
          state = update_commit_index(leader_commit, state)
          {true, state}
      end
      Peer.append_entries_reply(leader, current_term, reply, state)
      # Term is same or newer. If it's newer, we're supposed to adopt it.
      if term > current_term do
        set_current_term(term, state)
      else
        state
      end
    end
    %{state | last_heartbeat_seen: state.current_time}
  end

  defdelegate append_entries_reply(from, term, reply, state), to: Erix.Server.Common

  defdelegate request_vote(term, candidate_id, last_log_index, last_log_term, state), to: Erix.Server.Common

  defdelegate vote_reply(term, vote_granted, state), to: Erix.Server.Common

  defp update_commit_index(leader_commit, state) do
    new_commit_index = min(leader_commit, log_last_offset(state))
    %{state | commit_index: new_commit_index}
  end

end
