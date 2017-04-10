defmodule Erix.Server.Leader do
  @moduledoc """
  Server state behaviour
  """
  require Logger
  use Erix.Constants

  defmodule State do
    defstruct next_index: %{}, match_index: %{}
  end
  @behaviour Erix.Server

  # Explicitly specify :candidate here, other transitions aren't valid.
  def transition_from(:candidate, state) do
    {_, last_index} = get_last_term_and_index(state)
    next_index = Map.new(state.peers, fn(p) -> {p, last_index + 1} end)
    match_index = Map.new(state.peers, fn(p) -> {p, 0} end)
    leader_state = %State{next_index: next_index, match_index: match_index}
    state = %{state | state: :leader, current_state_data: leader_state}
    ping_peers(state)
    state
  end

  def tick(state) do
    # For now, send an empty append_entries on every tick. TODO optimize this
    ping_peers(state)
    state
  end

  # Not sure whether this is allowed, but let's give it a shot. At the very
  # least, makes testing a bit simpler. Note that there's some duplication
  # with `transition_from` that maybe needs cleanup.
  def add_peer(peer, state) do
    peers = [peer | state.peers]
    {_, last_index} = get_last_term_and_index(state)
    next_index = Map.put(state.current_state_data.next_index, peer, last_index + 1)
    match_index = Map.put(state.current_state_data.next_index, peer, 0)
    leader_state = %State{next_index: next_index, match_index: match_index}
    %{state | peers: peers, current_state_data: leader_state}
  end

  def client_command(client_id, command_id, terms_to_log, state) do
    # Append to log
    new_log = state.log ++ [{state.current_term, terms_to_log}]
    state = %{state | log: new_log}
    # Broadcast to peers
    ping_peers(state)
    state
  end

  defdelegate request_vote(pid, term, candidate_id, last_log_index, last_log_term), to: Erix.Server.Common

  defp ping_peers(state) do
    state.peers
    |> Enum.map(fn({mod, pid} = peer) ->
      next_index = Map.get(state.current_state_data.next_index, peer)
      entries_to_send = Enum.slice(state.log, (next_index - 1)..-1)
      prev_log_term = if next_index > 1 do
        # -1 because we move from next to previous; -1 to move from 1-base to 0-base
        {term, _} = Enum.at(state.log, next_index - 1 - 1)
        term
      else
        0
      end
      # TODO self() should be {Erix.Server, self()} but that happens in more places. Fix
      mod.request_append_entries(pid, state.current_term, self(),
        next_index - 1,
        prev_log_term,
        entries_to_send,
        state.commit_index
      )
    end)
  end

  defp get_last_term_and_index(state) do
    last_index = length(state.log)
    last_term = if last_index > 0 do
      last_log = Enum.at(state.log, last_index - 1)
    else
      0
    end
    {last_term, last_index}
  end
 end
