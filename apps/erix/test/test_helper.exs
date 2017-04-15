ExUnit.start()

defmodule ServerMaker do
  use Erix.Constants
  def new_follower do
    server_persistence = {nil, nil}
    {:ok, server} = Erix.Server.start_link(server_persistence)
    server
  end
  def new_primed_for_candidate do
    server = new_follower()
    for _ <- 1..@heartbeat_timeout_ticks, do: Erix.Server.tick(server)
    server
  end
  def new_candidate do
    server = new_primed_for_candidate()
    Erix.Server.tick(server)
    ensure_is(server, :candidate)
    server
  end
  def new_leader do
    server = new_candidate()
    Erix.Server.add_peer(server, {Erix.Server, self()})
    Erix.Server.vote_reply(server, 0, true)
    ensure_is(server, :leader)
    server
  end
  def ensure_is(server_pid, kind) do
    state = Erix.Server.__fortest__getstate(server_pid)
    if state.state != kind do
      raise "Something wrong, I expected to have a #{kind} here but got a #{state.state}"
    end
  end
end
