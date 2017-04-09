ExUnit.start()

defmodule ServerMaker do
  use Erix.Constants
  def new_follower do
    server_persistence = {nil, nil}
    {:ok, server} = Erix.Server.start_link(server_persistence)
    server
  end
  def new_primed_for_candidate do
    server = new_follower
    for _ <- 1..@election_timeout_ticks, do: Erix.Server.tick(server)
    server
  end
end
