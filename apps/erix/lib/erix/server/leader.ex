defmodule Erix.Server.Leader do
  @moduledoc """
  Server state behaviour
  """
  require Logger
  use Erix.Constants

  @behaviour Erix.Server

  def transition_from(:candidate, state) do
    state.peers
    |> Enum.map(fn({mod, pid}) ->
      # TODO make append_entries async.
      # TODO some fake stuff
      mod.append_entries(pid, state.current_term, self(),
        0, # fake prev_log_index
        0, # fake prev_log_term,
        [],
        0 # fake leader_commit
      )
    end)
    %{state | state: :leader}
  end
end
