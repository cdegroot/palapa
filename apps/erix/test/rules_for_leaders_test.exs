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
      expect_call request_append_entries(_pid, 0, self(), 0, 0, [], 0)
    end
    state = %Erix.Server.State{peers: [follower]}

    Erix.Server.Leader.transition_from(:candidate, state)

    Mock.verify(follower)
  end

  require Logger
  test "empty AppendEntries RPCs are sent regularly to prevent election timeouts" do
    {:ok, follower} = Mock.with_expectations do
      expect_call request_append_entries(_pid, 0, self(), 0, 0, [], 0)
    end
    state = %Erix.Server.State{}
    state = Erix.Server.Leader.transition_from(:candidate, state)
    state = Erix.Server.Leader.add_peer(follower, state)

    Erix.Server.Leader.tick(state)

    Mock.verify(follower)
  end

  test "apply command from clients to state machine, then respond" do
    # Where "apply to state machine" means have the append entry rpc executed by at least
    # half the followers (including the leader, which just writes it to log)
    {:ok, follower} = Mock.with_expectations do
      expect_call request_append_entries(_pid, 0, self(), 0, 0, [{0, {:some, "stuff"}}], 0)
    end
    {:ok, client} = Mock.with_expectations do
      expect_call command_completed(_pid, 12345)
    end
    state = %Erix.Server.State{}
    state = Erix.Server.Leader.transition_from(:candidate, state)
    state = Erix.Server.Leader.add_peer(follower, state)

    state = Erix.Server.Leader.client_command(client, 12345, {:some, "stuff"}, state)
    # Appended to local log
    assert state.log == [{0, {:some, "stuff"}}]
    # Broadcasted to followers
    Mock.verify(follower)
    # TODO Committed when quorum write (send an append_entries_reply "from" follower, that
    # should trigger quorum)
    # TODO Response to client
  end
end
