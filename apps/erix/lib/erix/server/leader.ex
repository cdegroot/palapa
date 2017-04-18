defmodule Erix.Server.Leader do
  @moduledoc """
  Server state behaviour
  """
  require Logger
  use Erix.Constants
  import Erix.Server.PersistentState
  import Simpler.TestSupport

  defmodule State do
    defstruct next_index: %{}, match_index: %{}, client_replies: %{}, last_ping: %{}
  end
  @behaviour Erix.Server

  # TODO timeout responses for last_ping so we retry. The problem here of course is
  # that we timeout last ping, send a new one, then get an answer for the old one
  # but interpret that as an answer for the new one. We probably need to send cookies
  # along so we can match requests and answers. A small 32 bit number would probably
  # suffice, for example a 32bit crc over the message contents.

  # Explicitly specify :candidate here, other transitions aren't valid.
  def transition_from(:candidate, state) do
    state = make_leader_state(state)
    ping_peers(state)
  end

  defp make_leader_state(state) do
    {_, last_index} = get_last_term_and_offset(state)
    next_index = Map.new(state.peers, fn(p) -> {p, last_index + 1} end)
    match_index = Map.new(state.peers, fn(p) -> {p, 0} end)
    leader_state = %State{next_index: next_index, match_index: match_index}
    %{state | state: :leader, current_state_data: leader_state}
  end
  deft _make_leader_state(state) do
    make_leader_state(state)
  end

  def tick(state) do
    # For now, send an empty append_entries on every tick. TODO optimize this
    ping_peers(state)
  end

  def add_peer(peer, state) do
    state = Erix.Server.Common.add_peer(peer, state)
    # Setup initial next/match index for peer
    {_, last_index} = get_last_term_and_offset(state)
    next_index = Map.put(state.current_state_data.next_index, peer, last_index + 1)
    match_index = Map.put(state.current_state_data.match_index, peer, 0)
    leader_state = %State{next_index: next_index, match_index: match_index}
    %{state | current_state_data: leader_state}
  end

  def client_command(client_id, command_id, terms_to_log, state) do
    # Append to log
    state = append_entries_to_log(log_last_offset(state) + 1, [{current_term(state), terms_to_log}], state)
    # Make a note when we can reply to the client.
    leader_state = state.current_state_data
    client_memo = {client_id, command_id}
    client_replies = Map.update(leader_state.client_replies, log_last_offset(state),
      [client_memo],
      fn(cur) -> [client_memo | cur] end)
    state = %{state | current_state_data: %{leader_state | client_replies: client_replies}}
    # Broadcast to peers
    ping_peers(state)
  end

  @doc """
  When a leader receives an AppendEntries RPC, we ignore it unless it has a newer term,
  then we transition to follower
  """
  def request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state) do
    if term > current_term(state) do
      mod = Erix.Server.state_module(:follower)
      state = mod.transition_from(state.state, state)
      # Let the follower state handle the actual call
      mod.request_append_entries(term, leader_id, prev_log_index, prev_log_term, entries, leader_commit, state)
    else
      state
    end
  end

  def append_entries_reply(from, term, reply, state) do
    current_term = current_term(state)
    do_append_entries_reply(from, term, reply, current_term, state)
  end
  defp do_append_entries_reply(_from, term, _repl, current_term, state)
  when term > current_term do
    mod = Erix.Server.state_module(:follower)
    state = set_current_term(term, state)
    mod.transition_from(state.state, state)
  end
  defp do_append_entries_reply(from, _term, false, _current_term, state) do
    leader_state = state.current_state_data
    last_ping = Map.delete(leader_state.last_ping, from)
    next_index = Map.update!(leader_state.next_index, from, fn(cur) -> cur - 1 end)
    %{state | current_state_data: %{leader_state | last_ping: last_ping, next_index: next_index}}
    # TODO maybe ping right away? For now, we ping again.
  end
  defp do_append_entries_reply(from, _term, true, _current_term, state) do
    leader_state = state.current_state_data
    outstanding_index = Map.get(leader_state.last_ping, from)
    if outstanding_index != nil do
      # Update match_index, next_index
      match_index = Map.put(leader_state.match_index, from, outstanding_index)
      next_index = Map.put(leader_state.next_index, from, outstanding_index + 1)
      # If this forwards the committed_index, do so
      commit_index = calculate_commit_index(match_index, log_last_offset(state), state.commit_index)
      # If this moves the committed_index past outstanding client replies, send replies.
      client_replies = reply_to_clients(leader_state.client_replies, commit_index)
      # Save state
      leader_state = %{leader_state | last_ping: Map.delete(leader_state.last_ping, from),
                       match_index: match_index,
                       next_index: next_index,
                      client_replies: client_replies}
      %{state | current_state_data: leader_state, commit_index: commit_index}
    else
      # We had nothing for the peer, ignore
      state
    end
  end

  defdelegate request_vote(pid, term, candidate_id, last_log_index, last_log_term), to: Erix.Server.Common

  defdelegate vote_reply(pid, vote_granted, term), to: Erix.Server.Common

  defp ping_peers(state) do
    leader_state = state.current_state_data
    last_index = log_last_offset(state)
    current_term = current_term(state)
    new_last_pings = state.peers
    |> Enum.map(fn({mod, pid} = peer) ->
      # Make sure we only ever have one outstanding appendEntries.
      current_ping = Map.get(leader_state.last_ping, peer)
      if current_ping == nil do
        next_index = Map.get(state.current_state_data.next_index, peer)
        entries_to_send = log_from(next_index, state)
        prev_log_term = if next_index > 1 do
          # -1 because we move from next to previous
          {term, _} = log_at(next_index - 1, state)
          term
        else
          0
        end
        mod.request_append_entries(pid, current_term, {Erix.Server, self()},
          next_index - 1,
          prev_log_term,
          entries_to_send,
          state.commit_index
        )
        {peer, last_index}
      else
        {peer, current_ping}
      end
    end)
    last_ping = Map.new(new_last_pings)
    %{state | current_state_data: %{leader_state | last_ping: last_ping}}
  end
  deft _ping_peers(state), do: ping_peers(state)

  defp get_last_term_and_offset(state) do
    last_offset = log_last_offset(state)
    {last_term, _} = log_at(last_offset, state)
    {last_term, last_offset}
  end

  # Send a reply to every client that has outstanding replies
  # below the commit index
  defp reply_to_clients(client_replies, commit_index) do
    client_replies
    |> Map.keys()
    |> Enum.reduce(client_replies, fn(offset, client_replies_acc) ->
      if offset <= commit_index do
        {clients, new_client_replies_acc} = Map.pop(client_replies_acc, offset)
        clients
        |> Enum.map(fn({client_id, command_id}) ->
          reply_to_client(client_id, command_id)
        end)
        new_client_replies_acc
      else
        client_replies_acc
      end
    end)
  end

  defp reply_to_client({client_mod, client_pid}, command_id) do
    client_mod.command_completed(client_pid, command_id)
  end

  # See what the highest commit index is we can get away with
  # match_index: the map of match index values for our peers, their committed offsets
  # last_index: the highest offset in our local log, our committed offset
  # commit_index: the current offset we have consensus for.
  defp calculate_commit_index(match_index, last_index, commit_index) do
    quorum = Float.floor(1 + (0.5 * Map.size(match_index)))
    votes = [last_index | Map.values(match_index)]
    # Stupid simple algorithm - just count forward from the commit_index and see
    # whether quorum is available for that index. The answer lies somwhere between
    # last_index and commit_index, inclusive. Number of peers is low and the range of
    # offsets usually too so this won't be slow even though there's some loop nesting
    (commit_index..last_index)
    |> Enum.reduce_while(commit_index, fn(offset, acc) ->
      votes_for_offset = Enum.count(votes, fn(vote) -> vote >= offset end)
      if votes_for_offset >= quorum do
        {:cont, offset}
      else
        {:halt, acc}
      end
    end)
  end
  deft _calculate_commit_index(match_index, last_index, commit_index) do
    calculate_commit_index(match_index, last_index, commit_index)
  end
 end
