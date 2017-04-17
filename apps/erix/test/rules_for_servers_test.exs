defmodule Erix.RulesForServersTest do
  use ExUnit.Case, async: true
  use Simpler.Mock

  @moduledoc """
  All Servers:
  • TODO If commitIndex > lastApplied: increment lastApplied, apply
    log[lastApplied] to state machine (§5.3)
  • If RPC request or response contains term T > currentTerm:
    set currentTerm = T, convert to follower (§5.1)
  """

  test "Follower accepts term if a newer term is seen in appendEntries request" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call append_entries_to_log(_pid, 1, [])
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_follower(db)
    leader = {Erix.Server, self()}

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
    leader = {Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Follower accepts term if a newer term is seen in requestVote" do
    leader = {Erix.Server, self()}
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
    leader = {Erix.Server, self()}
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
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call current_term(_pid), reply: 1
      expect_call log_at(_pid, 0), reply: nil
      expect_call append_entries_to_log(_pid, 1, [])
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_candidate(db)
    leader = {Erix.Server, self()}

    Erix.Server.request_append_entries(server, 2, leader, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Candidate becomes follower if a newer term is seen in appendEntries reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_candidate(db)
    leader = {Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Candidate becomes follower if a newer term is seen in requestVote" do
    leader = {Erix.Server, self()}
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
      expect_call current_term(_pid), reply: 2
      expect_call voted_for(_pid), reply: nil
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_voted_for(_pid, leader)
    end
    server = ServerMaker.new_candidate(db)

    Erix.Server.request_vote(server, 2, leader, 0, 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Candidate becomes follower if a newer term is seen in vote reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_candidate(db)
    leader = {Erix.Server, self()}

    Erix.Server.vote_reply(server, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Leader becomes follower if a newer term is seen in appendEntries request" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call current_term(_pid), reply: 1
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call log_last_offset(_pid), reply: 0
      expect_call current_term(_pid), reply: 1
      expect_call log_from(_pid, 1), reply: []
      expect_call current_term(_pid), reply: 1
      expect_call current_term(_pid), reply: 1
      expect_call log_at(_pid, 0), reply: nil
      expect_call append_entries_to_log(_pid, 1, [])
      expect_call log_last_offset(_pid), reply: 0
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_leader(db)
    leader = {Erix.Server, self()}

    Erix.Server.request_append_entries(server, 2, leader, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Leader becomes follower if a newer term is seen in appendEntries reply" do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call current_term(_pid), reply: 1
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call log_last_offset(_pid), reply: 0
      expect_call current_term(_pid), reply: 1
      expect_call log_from(_pid, 1), reply: []
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_leader(db)
    leader = {Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end

  test "Leader becomes follower if a newer term is seen in requestVote" do
    leader = {Erix.Server, self()}
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call current_term(_pid), reply: 1
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call log_last_offset(_pid), reply: 0
      expect_call current_term(_pid), reply: 1
      expect_call log_from(_pid, 1), reply: []
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
    leader = {Erix.Server, self()}
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call current_term(_pid), reply: 1
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call log_last_offset(_pid), reply: 0
      expect_call current_term(_pid), reply: 1
      expect_call log_from(_pid, 1), reply: []
      expect_call current_term(_pid), reply: 1
      expect_call set_current_term(_pid, 2)
    end
    server = ServerMaker.new_leader(db)

    Erix.Server.vote_reply(server, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    Mock.verify(db)
  end
end
