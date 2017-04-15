defmodule Erix.Server.Common do
  @moduledoc """
  Functions that are common between the states. States can delegate
  here. It implements the full behaviour with either a common-state
  function or an error logging function in case a certain callback
  does not make sense.
  """
  use Erix.Constants
  require Logger

  @behaviour Erix.Server

  def add_peer(peer_id, state) do
    %{state | peers: [peer_id | state.peers]}
  end

  def request_vote(term, candidate_id, last_log_index, last_log_term, state = %Erix.Server.State{current_term: current_term})
  when term > current_term do
    # We've seen a newer term - immediately transition to follower, no matter what
    # we were doing before.
    module = Erix.Server.state_module(:follower)
    # TODO persist current term
    state = module.transition_from(state.state, %{state | current_term: term})
    # And then we can most likely positively reply
    request_vote(term, candidate_id, last_log_index, last_log_term, state)
  end
  def request_vote(term, candidate_id, last_log_index, last_log_term, state) do
    {mod, pid} = candidate_id
    # TODO refactor this nested if/else hairball
    will_vote = if term < state.current_term do
      false
    else
      if state.voted_for == nil or state.voted_for == candidate_id do
        my_last_log_index = length(state.log)
        if my_last_log_index > last_log_index do
          false
        else
          if my_last_log_index == 0 do
            true
          else
            {my_last_log_term, _} = Enum.at(state.log, length(state.log) - 1)
            # we already established that candidate's log is equal or longer.
            if my_last_log_term > last_log_term do
              false
            else
              true
            end
          end
        end
      end
    end
    mod.vote_reply(pid, state.current_term, will_vote)
    # TODO persist voted_for
    voted_for = if will_vote, do: candidate_id, else: nil
    %{state | voted_for: voted_for}
  end

  def append_entries_reply(_from, term, _reply, state) do
    upgrade_term_if_newer_seen(term, state)
  end

  def vote_reply(term, _vote_granted, state) do
    upgrade_term_if_newer_seen(term, state)
  end

  defp upgrade_term_if_newer_seen(term, state) do
    if term > state.current_term do
      module = Erix.Server.state_module(:follower)
      # TODO persist current term
      module.transition_from(state.state, %{state | current_term: term})
    end
  end
end
