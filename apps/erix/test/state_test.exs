defmodule Erix.StateTest do
  use ExUnit.Case, async: true
  use Simpler.Mock

  @moduledoc """
  Tests for state. From the paper:

  Persistent state on all servers:
  (Updated on stable storage before responding to RPCs)
  currentTerm   latest term server has seen (initialized to 0
                on first boot, increases monotonically)
  votedFor      candidateId that received vote in current
                term (or null if none)
  log[]         log entries; each entry contains command
                for state machine, and term when entry
                was received by leader (first index is 1)

  Volatile state on all servers:
  commitIndex   index of highest log entry known to be
  committed     (initialized to 0, increases
                monotonically)
  lastApplied   index of highest log entry applied to state
                machine (initialized to 0, increases
                monotonically)

  Volatile state on leaders:
  (Reinitialized after election)
  nextIndex[]   for each server, index of the next log entry
                to send to that server (initialized to leader
                last log index + 1)
  matchIndex[]  for each server, index of highest log entry
                known to be replicated on server
                (initialized to 0, increases monotonically)

  Furthermore, "When servers start up, they begin as followers." (§5.2)
  """

  test "Initial state has the correct values" do
    {:ok, server_persistence} = Mock.with_expectations do
      expect_call fetch_current_term(_pid), reply: 0
      expect_call fetch_voted_for(_pid), reply: nil
      expect_call fetch_log(_pid), reply: []
    end
    {:ok, server} = Erix.Server.start_link(server_persistence)

    # Verify initial stable state - this must come from persistence
    # hence the expectations above we verify at the end of the test
    assert Erix.Server.current_term(server) == 0
    assert Erix.Server.voted_for(server) == nil
    assert Erix.Server.log(server) == []

    # Verify initial volatile state
    assert Erix.Server.commit_index(server) == 0
    assert Erix.Server.committed(server) == 0
    assert Erix.Server.last_applied(server) == 0

    # Verify that the server is a follower
    assert Erix.Server.__fortest__getstate(server).state == :follower

    Mock.verify(server_persistence)
  end
end
