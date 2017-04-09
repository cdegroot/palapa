defmodule Erix.RequestVoteRpcTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Invoked by candidates to gather votes (§5.2).

  Arguments:
  term               candidate’s term
  candidateId        candidate requesting vote
  lastLogIndex       index of candidate’s last log entry (§5.4)
  lastLogTerm        term of candidate’s last log entry (§5.4)

  Results:
  term               currentTerm, for candidate to update itself
  voteGranted        true means candidate received vote

  Receiver implementation:
  1. Reply false if term < currentTerm (§5.1)
  2. If votedFor is null or candidateId, and candidate’s log is at
     least as up-to-date as receiver’s log, grant vote (§5.2, §5.4)
  """
end
