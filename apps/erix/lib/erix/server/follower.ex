defmodule Erix.Server.Follower do
  @moduledoc """
  Implementation of Follower state
  """
  require Logger
  use Erix.Constants
  @behaviour Erix.Server

  def handle_tick(state) do
    if state.current_time - state.last_heartbeat_seen > @heartbeat_timeout_ticks do
      target = Erix.Server.state_module(:candidate)
      target.transition_from(:follower, state)
    else
      state
    end
  end

  @doc "Receive an AppendEntries RPC"
  def append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state) do
    # TODO not implemented yet
    {{state.current_term, true}, state}
  end

  def transition_from(_, state) do
    %{state | state: :follower}
  end
end
