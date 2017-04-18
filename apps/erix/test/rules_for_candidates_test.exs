defmodule Erix.RulesForCandidatesTest do
  use ExUnit.Case, async: true
  use Simpler.Mock
  use Erix.Constants

  @moduledoc """
  Candidates (§5.2):
  • On conversion to candidate, start election:
  • Increment currentTerm
  • Vote for self
  • Reset election timer
  • Send RequestVote RPCs to all other servers
  • If votes received from majority of servers: become leader
  • If AppendEntries RPC received from new leader: convert to
    follower
  • If election timeout elapses: start new election
  """

  test "A new candidate starts an election" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: nil
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
    end
    server = ServerMaker.new_primed_for_candidate(db)
    {:ok, follower} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0), reply: :ok
    end
    Erix.Server.add_peer(server, follower)

    # Convert to candidate
    Erix.Server.tick(server)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :candidate
    #assert state.current_term == 1
    assert state.current_state_data.vote_count == 1 # Immediately vote for self
    assert state.current_state_data.election_start == state.current_time

    Mock.verify(follower)
    Mock.verify(db)
  end

  test "Become leader if a majority of votes received" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: nil
      expect_call set_current_term(_pid, 1)
      expect_call current_term(_pid), reply: 1, times: :any
      expect_call log_last_offset(_pid), reply: 0, times: :any
      expect_call log_at(_pid, 0), reply: nil, times: :any
      expect_call log_from(_pid, 1), reply: [], times: 2
    end
    server = ServerMaker.new_primed_for_candidate(db)
    {:ok, follower_one} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0)
      expect_call request_append_entries(_pid, 1, _self, 0, 0, [], 0)
    end
    {:ok, follower_two} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0)
      expect_call request_append_entries(_pid, 1, _self, 0, 0, [], 0)
    end
    Erix.Server.add_peer(server, follower_one)
    Erix.Server.add_peer(server, follower_two)

    # Convert to candidate
    Erix.Server.tick(server)

    # Have one of the followers respond with a positive vote
    Erix.Server.vote_reply(server, 1, true)

    # One of the followers voted, plus the self-vote, which means we
    # should now be a leader
    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :leader

    Mock.verify(db)
    Mock.verify(follower_one)
    Mock.verify(follower_two)
  end

  test "Stay candidate while no quorum" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: nil
      expect_call set_current_term(_pid, 1)
      expect_call current_term(_pid), reply: 1, times: :any
      expect_call log_last_offset(_pid), reply: 0, times: :any
      expect_call log_at(_pid, 0), reply: nil, times: :any
    end
    server = ServerMaker.new_primed_for_candidate(db)
    {:ok, follower_one} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0)
    end
    {:ok, follower_two} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0)
    end
    {:ok, follower_three} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0)
    end
    {:ok, follower_four} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0)
    end
    Erix.Server.add_peer(server, follower_one)
    Erix.Server.add_peer(server, follower_two)
    Erix.Server.add_peer(server, follower_three)
    Erix.Server.add_peer(server, follower_four)

    # Convert to candidate
    Erix.Server.tick(server)

    # Have one of the followers respond with a positive vote
    Erix.Server.vote_reply(server, 1, true)

    # Two out of five is not a quorum, so we're still a candidate
    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :candidate

    Mock.verify(db)
    Mock.verify(follower_one)
    Mock.verify(follower_two)
    Mock.verify(follower_three)
    Mock.verify(follower_four)
  end

  test "Ignore false votes" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: nil
      expect_call set_current_term(_pid, 1)
      expect_call current_term(_pid), reply: 1, times: :any
      expect_call log_last_offset(_pid), reply: 0, times: :any
      expect_call log_at(_pid, 0), reply: nil, times: :any
    end
    server = ServerMaker.new_primed_for_candidate(db)
    {:ok, follower_one} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0)
    end
    {:ok, follower_two} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0)
    end
    Erix.Server.add_peer(server, follower_one)
    Erix.Server.add_peer(server, follower_two)

    # Convert to candidate
    Erix.Server.tick(server)

    # Have one of the followers respond with a negative vote
    Erix.Server.vote_reply(server, 1, false)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :candidate

    Mock.verify(db)
    Mock.verify(follower_one)
    Mock.verify(follower_two)
  end

  test "Candidate that receives AppendEntries becomes a follower" do
    {:ok, peer} = Mock.with_expectations do
      expect_call append_entries_reply(_pid, _from, 1, true)
    end
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call log_at(_pid, 0), reply: []
      expect_call append_entries_to_log(_pid, 1, [])
      expect_call log_last_offset(_pid), reply: 0
    end
    server = ServerMaker.new_candidate(db)

    Erix.Server.request_append_entries(server, 1, peer, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower

    Mock.verify(db)
    Mock.verify(peer)
  end

  test "If an election timeout elapses, a new election is started" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
    end
    server = ServerMaker.new_candidate(db)
    {:ok, follower} = Mock.with_expectations do
      # Expect the second vote request
      expect_call request_vote(_pid, 2, server, 0, 0), reply: :ok
    end
    Erix.Server.add_peer(server, follower)

    state = Erix.Server.__fortest__getstate(server)
    election_start = state.current_state_data.election_start

    for _ <- 0..@election_timeout_ticks do
      Erix.Server.tick(server)
    end

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :candidate
    assert election_start < state.current_state_data.election_start

    Mock.verify(follower)
    Mock.verify(db)
  end
end
