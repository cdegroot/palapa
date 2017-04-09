defmodule Erix.RulesForCandidatesTest do
  use ExUnit.Case, async: true
  use Simpler.Mock

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
    server = ServerMaker.new_primed_for_candidate()
    {:ok, follower} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0), reply: {1, true}
    end
    Erix.Server.add_peer(server, follower)

    # Convert to candidate
    Erix.Server.tick(server)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :candidate
    assert state.current_term == 1
    assert state.current_state_data.vote_count == 1 # Immediately vote for self
    assert state.current_state_data.election_start == state.current_time

    Mock.verify(follower)
  end

  test "Become leader if a majority of votes received" do
    server = ServerMaker.new_primed_for_candidate()
    {:ok, follower_one} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0), reply: :ok
    end
    {:ok, follower_two} = Mock.with_expectations do
      expect_call request_vote(_pid, 1, server, 0, 0), reply: :ok
    end
    Erix.Server.add_peer(server, follower_one)
    Erix.Server.add_peer(server, follower_two)

    # Convert to candidate
    Erix.Server.tick(server)

    # Have one of the followers respond with a positive vote
    Erix.Server.reply_vote(server, 1, true)

    # One of the followers voted, plus the self-vote, which means we
    # should now be a leader
    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :leader
  end
end
