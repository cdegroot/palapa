defmodule Erix.Server.Peer do
  @moduledoc """
  Utilities around the internal representation of peers. They are
  represented as `{uuid, module, pid}` triples. This module also
  contains methods to access the `:peers` part of the server state.
  """

  @type t :: {uuid :: binary, module :: atom, pid :: pid}

  # Peers state access

  def initial_state(state) do
    %Erix.Server.State{state | peers: []}
  end

  def known_peer?(peer, state) do
    state.peers
    |> Enum.any?(fn(p) -> uuid_of(p) == uuid_of(peer) end)
  end

  def peerless?(state) do
    count(state) == 0
  end

  def count(state) do
    length(state.peers)
  end

  def add_peer(new_peer, state) do
    np_mod = module_of(new_peer)
    np_pid = pid_of(new_peer)
    # Be nice, send our peers back for quick convergence.
    state.peers
    |> Enum.map(fn(peer) ->
      np_mod.add_peer(np_pid, peer)
    end)
    np_mod.add_peer(np_pid, self_peer(state))
    %{state | peers: [new_peer | state.peers]}
  end

  # Exception to the rule to keep state last...
  def map(state, function) do
    state.peers |> Enum.map(function)
  end

  # Peer triple management

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
