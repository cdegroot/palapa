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
    # The only way to make a candidate that doesn't immediately
    # conclude a succesful vote is to have a dummy follower that
    # won't vote. Tests need to realize that candidates and leaders
    # returned by this code will have a follower.
    {:ok, db} = Mock.with_expectations do
      expect_call current_term(_pid), reply: 0
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: 0
      expect_call log_at(_pid, 0), reply: nil
    end
    {:ok, follower} = Mock.with_expectations do
      # Eat everything
      expect_call request_vote(_pid, _term, _from, _last_log_index, _last_log_term), times: :any
      expect_call request_append_entries(_pid, _term, _leader, _prev_log_index, _prev_log_term, _entries, _leader_commit), times: :any
    end
    server = new_primed_for_candidate(db)
    Erix.Server.add_peer(server, follower)
    # Tick into candidate mode
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
      expect_call log_from(_pid, 1), reply: [], times: :any
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
