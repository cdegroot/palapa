defmodule Erix.Server.PeerTest do
  use ExUnit.Case, async: true
  use Simpler.Mock

  import Erix.Server.Peer

  test "a peer has defaults" do
    peer = Erix.Server.Peer.new()

    assert uuid_of(peer) != nil
    assert module_of(peer) == Erix.Server
    assert pid_of(peer) == self()
  end

  test "a peer can be constructed of preset values" do
    uuid = Erix.unique_id()
    peer = Erix.Server.Peer.new(uuid, __MODULE__, self())

    assert uuid_of(peer) == uuid
    assert module_of(peer) == __MODULE__
    assert pid_of(peer) == self()
  end

  test "just the UUID can be provided" do
    uuid = Erix.unique_id()
    peer = Erix.Server.Peer.new(uuid)

    assert uuid_of(peer) == uuid
    assert module_of(peer) == Erix.Server
    assert pid_of(peer) == self()
  end

  test "self peer" do
    uuid = Erix.unique_id()
    {:ok, db} = Mock.with_expectations do
      expect_call node_uuid(_state), reply: uuid
    end
    state = Erix.Server.PersistentState.initialize_persistence(db, %Erix.Server.State{})

    peer = self_peer(state)

    assert uuid_of(peer) == uuid
    assert module_of(peer) == Erix.Server
    assert pid_of(peer) == self()
  end
end
