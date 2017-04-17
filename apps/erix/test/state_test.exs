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
                committed (initialized to 0, increases
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
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: nil
      expect_call voted_for(_pid), reply: nil
      expect_call log_last_offset(_pid), reply: nil
      expect_call log_at(_pid, _offset), reply: nil, times: 5
    end

    {:ok, server} = Erix.Server.start_link(db)

    state = Erix.Server.__fortest__getstate(server)
    # Verify initial stable state - this must come from persistence
    # hence the expectations above we verify at the end of the test
    assert Erix.Server.PersistentState.current_term(state) == 0
    assert Erix.Server.PersistentState.voted_for(state) == nil
    assert Erix.Server.PersistentState.log_last_offset(state) == 0
    for i <- 1..5, do: assert Erix.Server.PersistentState.log_at(i, state) == {0, nil}

    # Verify initial volatile state
    assert state.commit_index == 0
    assert state.last_applied == 0

    # Verify that the server is a follower
    assert state.state == :follower

    Mock.verify(db)
  end
end
