defmodule Erix.ServerTest do
  use ExUnit.Case, async: true

  test "state_module calculation works" do
    assert Erix.Server.state_module(:leader) == Erix.Server.Leader
  end
end
