defmodule Erix.RulesForLeadersTest do
  use ExUnit.Case, async: true
  use Simpler.Mock
  require Logger

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
      expect_call request_append_entries(_pid, 0, _self, 0, 0, [], 0)
    end
    state = %Erix.Server.State{peers: [follower]}

    Erix.Server.Leader.transition_from(:candidate, state)

    Mock.verify(follower)
  end

  test "empty AppendEntries RPCs are sent regularly to prevent election timeouts" do
    {:ok, follower} = Mock.with_expectations do
      expect_call request_append_entries(_pid, 0, _self, 0, 0, [], 0)
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
      expect_call request_append_entries(_pid, 0, _self, 0, 0, [{0, {:some, "stuff"}}], 0)
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
    # Committed when quorum write.
    state = Erix.Server.Leader.append_entries_reply(follower, 0, true, state)
    # check next_index, commit_index
    leader_state = state.current_state_data

    # If successful, update next_index and match_index for follower
    assert Map.get(leader_state.next_index, follower) == 2
    assert Map.get(leader_state.match_index, follower) == 1

    # Move the commit index forward to the point of majority agreement.
    assert state.commit_index == 1

    # Reply to the client implies it got committed.
    Mock.verify(client)

    # We also shouldn't have outstanding client replies by now
    assert Map.size(leader_state.client_replies) == 0
  end

  test "A negative append entries reply decrements next index and pings again" do
    leader = {Erix.Server, self()}
    Logger.error("Leader = #{inspect leader}")
    {:ok, follower} = Mock.with_expectations do
      # This call is made on the transition from candidate
      expect_call request_append_entries(_pid, 3, leader, 6, 3, [], 5)
      # This call is made on the false response
      expect_call request_append_entries(_pid, 3, leader, 5, 2, [{3, 6}], 5)
    end
    log = [{0, 1}, {1, 12}, {1, 13}, {2, 4}, {2, 5}, {3, 6}]
    state = %Erix.Server.State{current_term: 3, commit_index: 5, log: log,
                               last_applied: 6, peers: [follower]}
    state = Erix.Server.Leader.transition_from(:candidate, state)

    state = Erix.Server.Leader.append_entries_reply(follower, 3, false, state)
    Erix.Server.Leader.ping_peers(state)

    Mock.verify(follower)
  end

  test "Send AppendEntries if last log index >= nextIndex for a follower" do
    leader = {Erix.Server, self()}
    log = [{0, 1}, {1, 12}, {1, 13}, {2, 4}, {2, 5}, {3, 6}]
    expected_log = Enum.slice(log, 4..-1)
    {:ok, follower} = Mock.with_expectations do
      expect_call request_append_entries(_pid, 3, leader, 4, 2, expected_log, 5)
    end
    state = %Erix.Server.State{current_term: 3, commit_index: 5, log: log,
                               last_applied: 6, peers: [follower]}
    state = Erix.Server.Leader.make_leader_state(state)
    leader_state = state.current_state_data
    next_index = Map.put(leader_state.next_index, follower, 5)
    state = %{state | current_state_data: %{leader_state | next_index: next_index}}

    Erix.Server.Leader.ping_peers(state)

    Mock.verify(follower)
  end
end
