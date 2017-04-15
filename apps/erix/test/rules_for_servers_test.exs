defmodule Erix.RulesForServersTest do
  use ExUnit.Case, async: true

  @moduledoc """
  All Servers:
  • TODO If commitIndex > lastApplied: increment lastApplied, apply
    log[lastApplied] to state machine (§5.3)
  • TODO If RPC request or response contains term T > currentTerm:
    set currentTerm = T, convert to follower (§5.1)
  """

end
