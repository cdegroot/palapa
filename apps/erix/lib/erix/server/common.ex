defmodule Erix.Server.Common do
  @moduledoc """
  Functions that are common between the states. States can delegate
  here. It implements the full behaviour with either a common-state
  function or an error logging function in case a certain callback
  does not make sense.
  """
  use Erix.Constants
  import Erix.Server.PersistentState

  require Logger

  @behaviour Erix.Server

  def add_peer({new_peer_mod, new_peer_pid} = new_peer_ref, state) do
    # TODO this is a bit messy. This happens because our self references are PIDs and
    # external node references are probably going to be names. Find a cleaner solution,
    # most likely by giving every peer some UUID - then we can stop caring about how peers
    # look from various angle, in-process, local, or remote.
    state = if Enum.any?(state.peers, fn({m, p}) -> m == new_peer_mod && real_pid(p) == real_pid(new_peer_pid) end) do
      state
    else
      # New node. Be nice, send our peers back for quick convergence.
      state.peers
      |> Enum.map(fn(peer) ->
        new_peer_mod.add_peer(new_peer_pid, peer)
      end)
      new_peer_mod.add_peer(new_peer_pid, {Erix.Server, self()})
      %{state | peers: [new_peer_ref | state.peers]}
    end
  end
  defp real_pid(pid), do: if is_atom(pid), do: Process.whereis(pid), else: pid

  def tick(_state) do
    raise "This function should not be called!"
  end

  def request_vote(term, candidate_id, last_log_index, last_log_term, state) do
    current_term = current_term(state)
    if term > current_term do
      # We've seen a newer term - immediately transition to follower, no matter what
      # we were doing before.
      module = Erix.Server.state_module(:follower)
      state = set_current_term(term, state)
      state = module.transition_from(state.state, state, "newer term in request_vote")
      # And then we can most likely positively reply
      request_vote(term, candidate_id, last_log_index, last_log_term, state)
    else
      {mod, pid} = candidate_id
      # TODO refactor this nested if/else hairball
      will_vote = if term < current_term do
        false
      else
        voted_for = voted_for(state)
        if voted_for == nil or voted_for == candidate_id do
          my_last_log_index = log_last_offset(state)
          if my_last_log_index > last_log_index do
            false
          else
            if my_last_log_index == 0 do
              true
            else
              {my_last_log_term, _} = log_at(my_last_log_index, state)
              # we already established that candidate's log is equal or longer.
              if my_last_log_term > last_log_term do
                false
              else
                true
              end
            end
          end
        else
          false
        end
      end
      voted_for = if will_vote, do: candidate_id, else: nil
      state = set_voted_for(voted_for, state)
      Logger.debug("#{inspect self()} vote for: #{inspect voted_for} as #{will_vote}")
      mod.vote_reply(pid, current_term, will_vote)
      state
    end
  end

  def request_append_entries(term, _leader_id, _prev_log_index, _prev_log_term, _entries, _leader_commit, state) do
    upgrade_term_if_newer_seen(term, state)
  end

  def append_entries_reply(_from, term, _reply, state) do
    upgrade_term_if_newer_seen(term, state)
  end

  def vote_reply(term, _vote_granted, state) do
    upgrade_term_if_newer_seen(term, state)
  end

  def upgrade_term_if_newer_seen(term, state) do
    if term > current_term(state) do
      state = set_current_term(term, state)
      module = Erix.Server.state_module(:follower)
      module.transition_from(state.state, state, "newer term seen in common")
    else
      state
    end
  end
end
