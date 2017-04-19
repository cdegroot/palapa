defmodule Erix.AppendEntriesRpcTest do
  use ExUnit.Case, async: true
  use Simpler.Mock
  alias Erix.Server.Peer
  require Logger

  @moduledoc """
  Invoked by leader to replicate log entries (§5.3); also used as
  heartbeat (§5.2).

  Arguments:
  term              leader’s term
  leaderId          so follower can redirect clients
  prevLogIndex      index of log entry immediately preceding
                    new ones
  prevLogTerm       term of prevLogIndex entry
  entries[]         log entries to store (empty for heartbeat;
                    may send more than one for efficiency)
  leaderCommit      leader’s commitIndex

  Results:
  term              currentTerm, for leader to update itself
  success           true if follower contained entry matching
                    prevLogIndex and prevLogTerm

  Receiver implementation:
  1. Reply false if term < currentTerm (§5.1)
  2. Reply false if log doesn’t contain an entry at prevLogIndex
     whose term matches prevLogTerm (§5.3)
  3. If an existing entry conflicts with a new one (same index
     but different terms), delete the existing entry and all that
     follow it (§5.3)
  4. Append any new entries not already in the log
  5. If leaderCommit > commitIndex, set commitIndex =
     min(leaderCommit, index of last new entry)
  """

  test "Reply false if append entries term is prior to our term" do
    # We can test this just on the follower. Leaders should not receive
    # AppendEntry and candidates will flip into follower mode before handling
    # it.
    {:ok, mock_node} = Mock.with_expectations do
      expect_call append_entries_reply(_pid, _from, 42, false)
    end
    mock_peer = Peer.for_mock(mock_node)
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: ServerMaker.fixed_uuid(), times: :any
      expect_call current_term(_pid), reply: 42
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{})

    Erix.Server.Follower.request_append_entries(41, mock_peer, 0, 0, [], 0, state)

    Mock.verify(mock_node)
    Mock.verify(db)
  end

  test "Reply false if log doesn't contain an entry at prevLogIndex whose term matches prevLogTerm" do
    {:ok, mock_node} = Mock.with_expectations do
      expect_call append_entries_reply(_pid, _from, 42, false)
    end
    mock_peer = Peer.for_mock(mock_node)
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: ServerMaker.fixed_uuid(), times: :any
      expect_call current_term(_pid), reply: 42
      expect_call log_at(_pid, 2), reply: {41, "bar"}
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{})

    Erix.Server.Follower.request_append_entries(42, mock_peer, 2, 42, [], 0, state)

    Mock.verify(mock_node)
    Mock.verify(db)
  end

  test "Rewrite log when an existing entry conflicts with a new one" do
    {:ok, mock_node} = Mock.with_expectations do
      expect_call append_entries_reply(_pid, _from, 42, true)
    end
    mock_peer = Peer.for_mock(mock_node)
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: ServerMaker.fixed_uuid(), times: :any
      expect_call current_term(_pid), reply: 42
      expect_call log_at(_pid, 2), reply: {42, "bar"}
      expect_call append_entries_to_log(_pid, 3, [{42, "mybaz"}, {42, "quux"}])
      expect_call log_last_offset(_pid), reply: 4
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{})
    Erix.Server.Follower.request_append_entries(42, mock_peer,
      2,
      42,
      [{42, "mybaz"}, {42, "quux"}], # this log conflicts with {43, "baz"}
      2, state)
    Mock.verify(mock_node)
    Mock.verify(db)
  end

  test "update commit_index if leader_commit > commit_index" do
    {:ok, mock_node} = Mock.with_expectations do
      expect_call append_entries_reply(_pid, _from, 42, true)
    end
    mock_peer = Peer.for_mock(mock_node)
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: ServerMaker.fixed_uuid(), times: :any
      expect_call current_term(_pid), reply: 42
      expect_call log_at(_pid, 3), reply: {42, "baz"}
      expect_call append_entries_to_log(_pid, 4, [{42, "mybaz"}, {42, "quux"}])
      expect_call log_last_offset(_pid), reply: 5
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{commit_index: 2})

    state = Erix.Server.Follower.request_append_entries(42, mock_peer,
      3, 42, [{42, "mybaz"}, {42, "quux"}],
      20,
      state)

    assert state.commit_index == 5
    Mock.verify(mock_node)
    Mock.verify(db)
  end
end
