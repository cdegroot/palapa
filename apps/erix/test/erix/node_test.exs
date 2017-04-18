defmodule Erix.NodeTest do
  use ExUnit.Case, async: true
  @moduletag :integration

  setup do
    random = :rand.uniform(1_000_000_000)
    db_name = "/tmp/nodetest.random"
    node_name = :"node.#{random}"
    on_exit fn ->
      File.rm_rf!(db_name)
    end
    [db_name: db_name, node_name: node_name]
  end
  test "Basic configuration sets up the structure we expect", context do
    {:ok, pid} = Erix.Node.start_link(Erix.LevelDB, context[:db_name], context[:node_name])

    Process.sleep(200) # Initialization, first one or two ticks

    assert Process.alive?(pid)
    assert Process.registered() |> Enum.any?(fn(n) -> n == context[:node_name] end)
    state = Erix.Server.__fortest__getstate(context[:node_name])
    assert state.state == :follower
    assert state.current_time > -1
  end

  # TODO setup stuff, wait a bit, check the sole node is a leader

  # TODO setup three nodes. Let them fight it out.
end
