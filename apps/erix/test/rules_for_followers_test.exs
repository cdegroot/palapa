defmodule Erix.RulesForFollowersTest do
  use ExUnit.Case, async: true
  use Erix.Constants
  use Simpler.Mock

  @moduledoc """
  Followers (§5.2):
  • Respond to RPCs from candidates and leaders
  • If election timeout elapses without receiving AppendEntries
    RPC from current leader or granting vote to candidate:
    convert to candidate
  """

  test "Followers will start an election after the election timeout elapses" do
    server_persistence = {nil, nil}
    {:ok, server} = Erix.Server.start_link(server_persistence)

    assert Erix.Server.__fortest__getstate(server).state == :follower

    for _ <- 0..@election_timeout_ticks do
      Erix.Server.tick(server)
    end

    assert Erix.Server.__fortest__getstate(server).state == :candidate
  end
end
