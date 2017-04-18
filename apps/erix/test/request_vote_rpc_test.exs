defmodule Erix.RequestVoteRpcTest do
  use ExUnit.Case, async: true
  use Simpler.Mock

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

  test "reply false on a request vote if term < currentTerm" do
    {:ok, mock_peer} = Mock.with_expectations do
      expect_call vote_reply(_pid, 33, false), reply: :ok
    end
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 33, times: :any
      expect_call set_voted_for(_pid, nil)
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{state: :follower})

    Erix.Server.Common.request_vote(20, mock_peer, 0, 0, state)

    Mock.verify(mock_peer)
    Mock.verify(db)
  end

  test "reply false if not voted, but logs are not sync" do
    {:ok, mock_peer} = Mock.with_expectations do
      expect_call vote_reply(_pid, 33, false), reply: :ok
    end
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 32
      expect_call set_current_term(_pid, 33) # Newer term seen, so we pick that one up
      expect_call current_term(_pid), reply: 33, times: :any
      expect_call voted_for(_pid), reply: nil
      expect_call log_last_offset(_pid), reply: 3
      expect_call set_voted_for(_pid, nil)
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{state: :follower})

    Erix.Server.Common.request_vote(33, mock_peer, 2, 4, state)

    Mock.verify(mock_peer)
    Mock.verify(db)
  end

  test "reply false if can vote, but candidate log is too short" do
    {:ok, mock_peer} = Mock.with_expectations do
      expect_call vote_reply(_pid, 33, false), reply: :ok
    end
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 32
      expect_call set_current_term(_pid, 33) # Newer term seen, so we pick that one up
      expect_call current_term(_pid), reply: 33, times: :any
      expect_call voted_for(_pid), reply: mock_peer
      expect_call log_last_offset(_pid), reply: 3
      expect_call set_voted_for(_pid, nil)
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{state: :follower})

    Erix.Server.Common.request_vote(33, mock_peer, 2, 4, state)

    Mock.verify(mock_peer)
    Mock.verify(db)
  end

  test "reply false if can vote, but last term is not correct" do
    {:ok, mock_peer} = Mock.with_expectations do
      expect_call vote_reply(_pid, 33, false), reply: :ok
    end
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 33, times: :any # For simplicity, we start at term 33
      expect_call voted_for(_pid), reply: mock_peer
      expect_call log_last_offset(_pid), reply: 3
      expect_call log_at(_pid, 3), reply: {32, "baz"}
      expect_call set_voted_for(_pid, nil)
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{state: :follower})

    Erix.Server.Common.request_vote(33, mock_peer, 3, 31, state)

    Mock.verify(mock_peer)
  end

  test "reply true if I'm a complete freshman - voting conditions will always hold" do
    {:ok, mock_peer} = Mock.with_expectations do
      expect_call vote_reply(_pid, 33, true), reply: :ok
    end
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: nil
      expect_call set_current_term(_pid, 33)
      expect_call current_term(_pid), reply: 33, times: :any
      expect_call voted_for(_pid), reply: nil
      expect_call log_last_offset(_pid), reply: nil
      expect_call set_voted_for(_pid, mock_peer)
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{state: :follower})

    Erix.Server.Common.request_vote(33, mock_peer, 2, 4, state)

    Mock.verify(mock_peer)
  end

  test "reply true if voting conditions hold" do
    {:ok, mock_peer} = Mock.with_expectations do
      expect_call vote_reply(_pid, 33, true), reply: :ok
    end
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 33
      expect_call voted_for(_pid), reply: mock_peer
      expect_call log_last_offset(_pid), reply: 3
      expect_call log_at(_pid, 3), reply: {32, "baz"}
      expect_call set_voted_for(_pid, mock_peer)
    end
    state = Erix.Server.PersistentState._set_persister(db, %Erix.Server.State{state: :follower})

    Erix.Server.Common.request_vote(33, mock_peer, 3, 32, state)

    Mock.verify(mock_peer)
    Mock.verify(db)
  end
end
