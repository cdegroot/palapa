defmodule Erix.Server.Leader do
  @moduledoc """
  Server state behaviour
  """
  require Logger
  use Erix.Constants

  defmodule State do
    defstruct next_index: [], match_index: []
  end
  @behaviour Erix.Server

  def transition_from(:candidate, state) do
    ping_peers(state)
    %{state | state: :leader}
  end

  def tick(state) do
    # For now, send an empty append_entries on every tick. TODO optimize this
    ping_peers(state)
    state
  end

  defp ping_peers(state) do
    state.peers
    |> Enum.map(fn({mod, pid}) ->
      # TODO make append_entries async or parallel with tasks
      # TODO some fake stuff, also we don't handle responses.
      mod.request_append_entries(pid, state.current_term, self(),
        0, # fake prev_log_index
        0, # fake prev_log_term,
        [],
        0 # fake leader_commit
      )
    end)
  end

  defdelegate request_vote(pid, term, candidate_id, last_log_index, last_log_term), to: Erix.Server.Common
end
