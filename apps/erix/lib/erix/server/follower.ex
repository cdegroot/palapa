defmodule Erix.Server.Follower do
  @moduledoc """
  Implementation of Follower state
  """
  require Logger
  use Erix.Constants
  @behaviour Erix.Server

  def tick(state) do
    if state.current_time - state.last_heartbeat_seen > @heartbeat_timeout_ticks do
      target = Erix.Server.state_module(:candidate)
      target.transition_from(:follower, state)
    else
      state
    end
  end

  @doc "Receive an AppendEntries RPC"
  def append_entries(term, _, _, _, _, _, state = %Erix.Server.State{current_term: current_term})
  when term < current_term do
    # Bad term, send the current term back
    {{state.current_term, false}, state}
  end
  def append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state) do
    prev_log_entry = if length(state.log) >= prev_log_index do
      Enum.at(state.log, prev_log_index - 1)
    else
      nil
    end
    case prev_log_entry do
      nil ->
        {{state.current_term, false}, state}
      {pl_term, _} when pl_term != prev_log_term ->
        {{state.current_term, false}, state}
      _ ->
        state = append_entries_to_log(prev_log_index, entries, state)
        state = update_commit_index(leader_commit, state)
        {{state.current_term, true}, state}
    end
  end

  def transition_from(_, state) do
    %{state | state: :follower}
  end

  defp append_entries_to_log(prev_log_index, entries, state) do
    # TODO persist log (synchronously, before responding)

    # This is a bit of a shortcut, but it should work - if we agree on the previous
    # log index, we can basically truncate our log and append the new entries. It does
    # not really matter what we had before, as long as we agree with the leader. This line
    # basically step 3. and 4. of the AppendEntries RPC receiver specification.
    new_log = Enum.slice(state.log, 0, prev_log_index) ++ entries
    %{state | log: new_log}
  end

  defp update_commit_index(leader_commit, state) do
    new_commit_index = min(leader_commit, length(state.log))
    %{state | commit_index: new_commit_index}
  end
end