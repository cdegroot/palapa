defmodule Erix.RulesForServersTest do
  use ExUnit.Case, async: true

  @moduledoc """
  All Servers:
  • TODO If commitIndex > lastApplied: increment lastApplied, apply
    log[lastApplied] to state machine (§5.3)
  • If RPC request or response contains term T > currentTerm:
    set currentTerm = T, convert to follower (§5.1)
  """

  test "Follower accepts term if a newer term is seen in appendEntries request" do
    server = ServerMaker.new_follower()
    leader = {Erix.Server, self()}

    Erix.Server.request_append_entries(server, 2, leader, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Follower accepts term if a newer term is seen in appendEntries reply" do
    server = ServerMaker.new_follower()
    leader = {Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Follower accepts term if a newer term is seen in requestVote" do
    server = ServerMaker.new_follower()
    leader = {Erix.Server, self()}

    Erix.Server.request_vote(server, 2, leader, 0, 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Follower accepts term if a newer term is seen in vote reply" do
    server = ServerMaker.new_follower()
    leader = {Erix.Server, self()}

    Erix.Server.vote_reply(server, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Candidate becomes follower if a newer term is seen in appendEntries request" do
    server = ServerMaker.new_candidate()
    leader = {Erix.Server, self()}

    Erix.Server.request_append_entries(server, 2, leader, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Candidate becomes follower if a newer term is seen in appendEntries reply" do
    server = ServerMaker.new_candidate()
    leader = {Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Candidate becomes follower if a newer term is seen in requestVote" do
    server = ServerMaker.new_candidate()
    leader = {Erix.Server, self()}

    Erix.Server.request_vote(server, 2, leader, 0, 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Candidate becomes follower if a newer term is seen in vote reply" do
    server = ServerMaker.new_candidate()
    leader = {Erix.Server, self()}

    Erix.Server.vote_reply(server, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Leader becomes follower if a newer term is seen in appendEntries request" do
    server = ServerMaker.new_leader()
    leader = {Erix.Server, self()}

    Erix.Server.request_append_entries(server, 2, leader, 0, 0, [], 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Leader becomes follower if a newer term is seen in appendEntries reply" do
    server = ServerMaker.new_leader()
    leader = {Erix.Server, self()}

    Erix.Server.append_entries_reply(server, leader, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Leader becomes follower if a newer term is seen in requestVote" do
    server = ServerMaker.new_leader()
    leader = {Erix.Server, self()}

    Erix.Server.request_vote(server, 2, leader, 0, 0)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end

  test "Leader becomes follower if a newer term is seen in vote reply" do
    server = ServerMaker.new_leader()
    leader = {Erix.Server, self()}

    Erix.Server.vote_reply(server, 2, true)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :follower
    assert state.current_term == 2
  end
end
