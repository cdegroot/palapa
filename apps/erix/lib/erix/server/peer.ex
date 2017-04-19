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

  # Forwarding calls refactored out of production code

  def request_vote(peer, current_term, last_log_index, last_log_term, state) do
    module_of(peer).request_vote(pid_of(peer), current_term,
      self_peer(state), last_log_index, last_log_term)
  end

  def vote_reply(peer, current_term, will_vote) do
    module_of(peer).vote_reply(pid_of(peer), current_term, will_vote)
  end

  def request_append_entries(peer, term, prev_log_index, prev_log_term,
                             entries, leader_commit, state) do
    module_of(peer).request_append_entries(pid_of(peer), term,
      self_peer(state), prev_log_index, prev_log_term, entries, leader_commit)
  end

  def append_entries_reply(peer, term, reply, state) do
    module_of(peer).append_entries_reply(pid_of(peer), self_peer(state), term, reply)
  end


  import Simpler.TestSupport

  deft for_mock({mod, pid}), do: new(UUID.uuid4, mod, pid)
end
