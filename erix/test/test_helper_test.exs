defmodule Erix.TestHelperTest do
  use ExUnit.Case, async: true
  use Simpler.Mock

  @moduledoc """
  The follower, candidate, leader setups in test helpers are sufficiently complex to
  warrant testing. If they break, mock expectations may move to other parts of the
  system making for complex debugging. The tests here serve as an early warning system.
  """

  test "new follower" do
    {:ok, db} = Mock.with_expectations do
    end
    ServerMaker.new_follower(db)
    Mock.verify(db)
  end
  test "new primed for candidate" do
    {:ok, db} = Mock.with_expectations do
    end
    ServerMaker.new_primed_for_candidate(db)
    Mock.verify(db)
  end
  test "new candidate" do
    {:ok, db} = Mock.with_expectations do
    end
    ServerMaker.new_candidate(db)
    Mock.verify(db)
  end
  test "new leader" do
    {:ok, db} = Mock.with_expectations do
    end
    ServerMaker.new_leader(db)
    Mock.verify(db)
  end
end
