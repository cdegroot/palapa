defmodule Erix.RulesForLeadersTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Leaders:
  • Upon election: send initial empty AppendEntries RPCs
    (heartbeat) to each server; repeat during idle periods to
    prevent election timeouts (§5.2)
  • If command received from client: append entry to local log,
    respond after entry applied to state machine (§5.3)
  • If last log index ≥ nextIndex for a follower: send
    AppendEntries RPC with log entries starting at nextIndex
  • If successful: update nextIndex and matchIndex for
    follower (§5.3)
  • If AppendEntries fails because of log inconsistency:
    decrement nextIndex and retry (§5.3)
  • If there exists an N such that N > commitIndex, a majority
    of matchIndex[i] ≥ N, and log[N].term == currentTerm:
    set commitIndex = N (§5.3, §5.4).
  """
end
