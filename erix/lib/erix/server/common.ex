defmodule Erix.Server.Common do
  @moduledoc """
  Functions that are common between the states. States can delegate
  here. It implements the full behaviour with either a common-state
  function or an error logging function in case a certain callback
  does not make sense.

  Also contains some utilities that are common to multiple states.
  """
  use Erix.Constants
  import Erix.Server.PersistentState
  alias Erix.Server.Peer

  require Logger

  @behaviour Erix.Server

  def add_peer(new_peer, state) do
    if Peer.known_peer?(new_peer, state) do
      state
    else
      Peer.add_peer(new_peer, state)
    end
  end

  defp transition_to(state_atom, state, reason) do
    mod = Erix.Server.state_module(state_atom)
    mod.transition_from(state.state, state, reason)
  end

  def tick(_state) do
    raise "This function should not be called!"
  end

  def request_vote(term, candidate, last_log_index, last_log_term, state) do
    current_term = current_term(state)
    if term > current_term do
      # We've seen a newer term - immediately transition to follower, no matter what
      # we were doing before.
      state = set_current_term(term, state)
      state = transition_to(:follower, state, "newer term in request_vote")
      # And then we can most likely positively reply
      Erix.Server.Follower.request_vote(term, candidate, last_log_index, last_log_term, state)
    else
      # There's a whole list of conditions we need to check..
      # - we agree on the term
      will_vote = term >= current_term
      # - we haven't voted for anyone else
      will_vote = will_vote and (
        voted_for = voted_for(state)
        voted_for == nil or voted_for == candidate)
      # - we don't have conflicting logs.
      will_vote = will_vote and (
          my_last_log_index = log_last_offset(state)
          my_last_log_index == 0 or (my_last_log_index <= last_log_index and (
              {my_last_log_term, _} = log_at(my_last_log_index, state)
              # we already established that candidate's log is equal or longer.
              my_last_log_term <= last_log_term)))
      voted_for = if will_vote, do: candidate, else: nil
      state = set_voted_for(voted_for, state)
      Logger.debug("#{inspect self()} vote for: #{inspect voted_for} as #{will_vote}")
      Peer.vote_reply(candidate, current_term, will_vote)
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
      transition_to(:follower, state, "newer term seen in common")
    else
      state
    end
  end

  @doc """
  If our commit index has been updated, we need to signal our local client
  to update its state.
  """
  def signal_client(current_commit_index, new_commit_index, state) do
    # TODO I don't really like how we construct the client reference here.
    # Maybe something observer-style? The Process.registered() call makes it
    # a complete hack.
    client_name = Erix.Node.client_name(state.node_name)
    client_exists = Process.registered() |> Enum.any?(fn(n) -> n == client_name end)
    if new_commit_index > current_commit_index and client_exists do
      for offset <- (current_commit_index + 1)..new_commit_index do
        {_offset, entry} = log_at(offset, state)
        Erix.Client.apply_state(client_name, entry)
      end
    end
  end
end
