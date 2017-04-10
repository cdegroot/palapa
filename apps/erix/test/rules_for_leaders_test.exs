defmodule Erix.RulesForLeadersTest do
  use ExUnit.Case, async: true
  use Simpler.Mock

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

  test "upon election, send initial empty AppendEntries RPCs" do
    # Note - transitioning into leader state is tricky. Let's try testing
    # the module directly.
    {:ok, follower} = Mock.with_expectations do
      expect_call append_entries(_pid, 0, self(), 0, 0, [], 0), reply: {0, true}
    end
    state = %Erix.Server.State{peers: [follower]}
    Erix.Server.Leader.transition_from(:candidate, state)

    Mock.verify(follower)
  end

  test "empty AppendEntries RPCs are sent regularly to prevent election timeouts" do
    {:ok, follower} = Mock.with_expectations do
      expect_call append_entries(_pid, 0, self(), 0, 0, [], 0), reply: {0, true}
    end
    state = %Erix.Server.State{}
    state = Erix.Server.Leader.transition_from(:candidate, state)

    state = %{state | peers: [follower]}

    Erix.Server.Leader.tick(state)

    Mock.verify(follower)
  end
end
