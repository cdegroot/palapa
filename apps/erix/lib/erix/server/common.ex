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
    if term < state.current_term do
      mod.vote_reply(pid, state.current_term, false)
    end
    state
  end


end
