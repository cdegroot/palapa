defmodule Erix.AppendEntriesRpcTest do
  use ExUnit.Case, async: true

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
    state = %Erix.Server.State{current_term: 42}
    {reply, _} = Erix.Server.Follower.append_entries(41, self(), 0, 0, [], 0, state)
    assert reply == {42, false}
  end

  test "Reply false if log doesn't contain an entry at prevLogIndex whose term matches prevLogTerm" do
    state = %Erix.Server.State{current_term: 42, log: [{41, "foo"}, {41, "bar"}]}
    {reply, _} = Erix.Server.Follower.append_entries(42, self(), 2, 42, [], 0, state)
    assert reply == {42, false}
  end

  test "Rewrite log when an existing entry conflicts with a new one" do
    state = %Erix.Server.State{current_term: 42, log: [{41, "foo"}, {42, "bar"}, {43, "baz"}]}
    {reply, state} = Erix.Server.Follower.append_entries(42, self(),
      2,
      42,
      [{42, "mybaz"}, {42, "quux"}], # this log conflicts with {43, "baz"}
      2, state)
    assert reply == {42, true}
    assert state.log == [{41, "foo"}, {42, "bar"}, {42, "mybaz"}, {42, "quux"}]
  end

  test "update commit_index is leader_commit > commit_index" do
    state = %Erix.Server.State{current_term: 42, log: [{41, "foo"}, {42, "bar"}, {42, "baz"}],
                              commit_index: 2}
    {reply, state} = Erix.Server.Follower.append_entries(42, self(),
      3, 42, [{42, "mybaz"}, {42, "quux"}],
      20,
      state)
    assert reply == {42, true}
    assert state.log == [{41, "foo"}, {42, "bar"}, {42, "baz"}, {42, "mybaz"}, {42, "quux"}]
    assert state.commit_index == 5
  end
end
