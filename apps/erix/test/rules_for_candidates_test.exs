defmodule Erix.RulesForCandidatesTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Candidates (§5.2):
  • On conversion to candidate, start election:
  • Increment currentTerm
  • Vote for self
  • Reset election timer
  • Send RequestVote RPCs to all other servers
  • If votes received from majority of servers: become leader
  • If AppendEntries RPC received from new leader: convert to
    follower
  • If election timeout elapses: start new election
  """

  test "A new candidate starts an election" do
    server = ServerMaker.new_primed_for_candidate()

    # Convert to candidate
    Erix.Server.tick(server)

    state = Erix.Server.__fortest__getstate(server)
    assert state.state == :candidate
    assert state.current_term == 1
    assert state.current_state_data.votes == [server]
    assert state.current_state_data.election_start == state.current_time
  end
end
