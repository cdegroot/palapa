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
end
