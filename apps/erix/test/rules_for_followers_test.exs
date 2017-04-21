defmodule Erix.RulesForFollowersTest do
  use ExUnit.Case, async: true
  use Erix.Constants
  use Simpler.Mock
  alias Erix.Server.Peer

  @moduledoc """
  Followers (§5.2):
  • TODO? Respond to RPCs from candidates and leaders
  • If election timeout elapses without receiving AppendEntries
    RPC from current leader or granting vote to candidate:
    convert to candidate
  """

  test "Followers will start an election after the election timeout elapses" do
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: UUID.uuid4()
      expect_call current_term(_pid), reply: nil
      expect_call set_current_term(_pid, 1)
      expect_call log_last_offset(_pid), reply: nil, times: :any
      expect_call log_at(_pid, 0), reply: nil
      expect_call log_from(_pid, 1), reply: []
    end
    {:ok, server} = Erix.Server.start_link(db, ServerMaker.random_node_name)

    assert Erix.Server.__fortest__getstate(server).state == :follower

    for _ <- 0..@heartbeat_timeout_ticks do
      Erix.Server.tick(server)
    end

    # Peers is empty so on the last tick, we move to candidate, win the election by
    # absence of any voters, and thus declare ourselves leader.
    assert Erix.Server.__fortest__getstate(server).state == :leader
  end

  test "Follower keeps a reference to the leader" do
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_pid), reply: ServerMaker.fixed_uuid()
      expect_call current_term(_pid), reply: 0
      expect_call log_at(_pid, _offset), reply: nil
      expect_call set_current_term(_pid, _term)
    end
    follower_node = ServerMaker.new_follower(db)
    {:ok, leader_node} = Mock.with_expectations do
      expect_call append_entries_reply(_pid, _follower_node, _offset, _reply)
    end
    leader_peer = Peer.for_mock(leader_node)

    Erix.Server.request_append_entries(follower_node, 1, leader_peer, 1, 1, [], 1)

    follower_state = Erix.Server.__fortest__getstate(follower_node).current_state_data
    assert follower_state.leader == leader_peer
  end

  test "A new follower can't forward client commands" do
    follower_state = Erix.Server.Follower.transition_from(:start, %Erix.Server.State{})

    {:error, :leader_not_yet_known} = Erix.Server.Follower.client_command(self(), 1234, {:foo, "bar"}, follower_state)
  end

  test "A follower forwards client commands to the leader" do
    {:ok, leader_node} = Mock.with_expectations do
      expect_call client_command(_pid, 1234, {:foo, "bar"}, _state)
    end
    leader_peer = Peer.for_mock(leader_node)
    follower_state = Erix.Server.Follower.transition_from(:start, %Erix.Server.State{})
    follower_state = %{follower_state | current_state_data: %{follower_state.current_state_data | leader: leader_peer}}

    :ok = Erix.Server.Follower.client_command(self(), 1234, {:foo, "bar"}, follower_state)

    Mock.verify(leader_node)
  end
end
