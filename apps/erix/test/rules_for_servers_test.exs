defmodule Erix.RulesForServersTest do
  use ExUnit.Case, async: true
  use Simpler.Mock
  alias Erix.Server.Peer

  @moduledoc """
  All Servers:
  • TODO If commitIndex > lastApplied: increment lastApplied, apply
    log[lastApplied] to state machine (§5.3)
  • If RPC request or response contains term T > currentTerm:
    set currentTerm = T, convert to follower (§5.1)
  """

  test "Follower accepts term if a newer term is seen in appendEntries request" do
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: ServerMaker.fixed_uuid(), times: :any
      expect_call current_term(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call append_entries_to_log(_pid, 1, [])
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_follower(db)
    leader = {Erix.unique_id(), Erix.Server, self()}

    Erix.Server.request_append_entries(server, 2, leader, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Follower accepts term if a newer term is seen in appendEntries reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_follower(db)
    leader = {Erix.unique_id(), Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Follower accepts term if a newer term is seen in requestVote" do
    leader = {Erix.unique_id(), Erix.Server, self()}
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
      expect_call current_term(_pid), reply: 2
      expect_call voted_for(_pid), reply: nil
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_voted_for(_pid, leader)
    end
    server = ServerMaker.new_follower(db)

    Erix.Server.request_vote(server, 2, leader, 0, 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Follower accepts term if a newer term is seen in vote reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_follower(db)

    Erix.Server.vote_reply(server, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Candidate becomes follower if a newer term is seen in appendEntries request" do
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: ServerMaker.fixed_uuid(), times: :any
      expect_call current_term(_pid), reply: 1
      expect_call log_at(_pid, 0), reply: nil
      expect_call append_entries_to_log(_pid, 1, [])
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_candidate(db)
    leader = {Erix.unique_id(), Erix.Server, self()}

    Erix.Server.request_append_entries(server, 2, leader, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Candidate becomes follower if a newer term is seen in appendEntries reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_candidate(db)
    leader = {Erix.unique_id(), Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Candidate becomes follower if a newer term is seen in requestVote" do
    leader = {Erix.unique_id(), Erix.Server, self()}
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_candidate(db)

    Erix.Server.request_vote(server, 2, leader, 0, 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Candidate becomes follower if a newer term is seen in vote reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_candidate(db)

    Erix.Server.vote_reply(server, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Leader becomes follower if a newer term is seen in appendEntries request" do
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: ServerMaker.fixed_uuid(), times: :any
      expect_call current_term(_pid), reply: 1
      expect_call current_term(_pid), reply: 1
      expect_call log_at(_pid, 0), reply: nil
      expect_call append_entries_to_log(_pid, 1, [])
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_leader(db)
    leader = {Erix.unique_id(), Erix.Server, self()}

    Erix.Server.request_append_entries(server, 2, leader, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Leader becomes follower if a newer term is seen in appendEntries reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_leader(db)
    leader = {Erix.unique_id(), Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Leader becomes follower if a newer term is seen in requestVote" do
    leader = {Erix.unique_id(), Erix.Server, self()}
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
      expect_call current_term(_pid), reply: 2
      expect_call voted_for(_pid), reply: nil
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_voted_for(_pid, leader)
    end
    server = ServerMaker.new_leader(db)

    Erix.Server.request_vote(server, 2, leader, 0, 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Leader becomes follower if a newer term is seen in vote reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_leader(db)

    Erix.Server.vote_reply(server, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Optimization: add_peer gets reciprocal call" do
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: Erix.unique_id(), times: :any
    end
    node = ServerMaker.new_follower(db)
    node_peer = Erix.Server.__fortest__getpeer(node)
    {:ok, peer_one} = Mock.with_expectations do
      expect_call add_peer(_self, node_peer)
    end
    node_one_peer = Peer.for_mock(peer_one)
    {:ok, peer_two} = Mock.with_expectations do
      expect_call add_peer(_self, node_one_peer)
      expect_call add_peer(_self, node_peer)
    end
    node_two_peer = Peer.for_mock(peer_two)

    Erix.Server.add_peer(node, node_one_peer)
    Erix.Server.add_peer(node, node_two_peer)

    Process.sleep(10) # Async stuff going on, wait a bit

    Mock.verify(db)
    Mock.verify(peer_one)
    Mock.verify(peer_two)
  end
end
