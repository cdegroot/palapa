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

  def request_vote(term, candidate_id, last_log_index, last_log_term, state) do
    {mod, pid} = candidate_id
    # TODO refactor this nested if/else hairball
    if term < state.current_term do
      mod.vote_reply(pid, state.current_term, false)
    else
      if state.voted_for == nil or state.voted_for == candidate_id do
        my_last_log_index = length(state.log)
        if my_last_log_index > last_log_index do
          mod.vote_reply(pid, state.current_term, false)
        else
          if my_last_log_index == 0 do
            mod.vote_reply(pid, state.current_term, true)
          else
            {my_last_log_term, _} = Enum.at(state.log, length(state.log) - 1)
            # we already established that candidate's log is equal or longer.
            if my_last_log_term > last_log_term do
              mod.vote_reply(pid, state.current_term, false)
            else
              mod.vote_reply(pid, state.current_term, true)
            end
          end
        end
      end
    end
    state
  end


end
