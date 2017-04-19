defmodule Erix.Server.Peer do
  @moduledoc """
  Utilities around the internal representation of peers. They are
  represented as {uuid, module, pid} triples.
  """

  @type t :: {uuid :: binary, module :: atom, pid :: pid}

  @doc "Make a completely new Peer, pointing to myself"
  def new do
    {UUID.uuid1(), Erix.Server, self()}
  end

  @doc "Make a new Peer with the indicated values"
  def new(uuid, module, pid) do
    {uuid, module, pid}
  end

  @doc "Make a new Peer with just the UUID"
  def new(uuid) do
    {uuid, Erix.Server, self()}
  end

  @doc "Return the uuid of the peer"
  def uuid_of({uuid, _, _}), do: uuid

  @doc "Return the module of the peer"
  def module_of({_, module, _}), do: module

  @doc "Return the pid of the peer"
  def pid_of({_, _, pid}), do: pid

  @doc "Return a peer ref for the current process/server"
  def self_peer(state) do
    new(Erix.Server.PersistentState.node_uuid(state), Erix.Server, self())
  end

  import Simpler.TestSupport

  deft for_mock({mod, pid}), do: new(UUID.uuid4, mod, pid)
end
