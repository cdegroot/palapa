ExUnit.start()

defmodule ServerMaker do
  use Erix.Constants
  use Simpler.Mock
  def new_follower(persistence) do
    {:ok, server} = Erix.Server.start_link(persistence)
    server
  end
  def new_primed_for_candidate(persistence) do
    server = new_follower(persistence)
    for _ <- 1..@heartbeat_timeout_ticks, do: Erix.Server.tick(server)
    server
  end
  def new_candidate(persistence) do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
    end
    server = new_primed_for_candidate(db)
    Erix.Server.tick(server)
    ensure_is(server, :candidate)
    Erix.Server.__fortest__setpersister(server, persistence)
    Mock.verify(db)
    server
  end
  def new_leader(persistence) do
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 1
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
      expect_call log_last_offset(_pid), reply: 0
      expect_call current_term(_pid), reply: 1
      expect_call log_from(_pid, 1), reply: []
    end
    server = new_candidate(db)
    Erix.Server.add_peer(server, {Erix.Server, self()})
    Erix.Server.vote_reply(server, 0, true)
    ensure_is(server, :leader)
    Erix.Server.__fortest__setpersister(server, persistence)
    Mock.verify(db)
    server
  end
  def ensure_is(server_pid, kind) do
    state = Erix.Server.__fortest__getstate(server_pid)
    if state.state != kind do
      raise "Something wrong, I expected to have a #{kind} here but got a #{state.state}"
    end
  end
end
