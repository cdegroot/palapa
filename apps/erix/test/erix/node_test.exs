defmodule Erix.NodeTest do
  use ExUnit.Case, async: true
  require Logger

  @moduletag :integration

  setup do
    do_setup()
  end
  defp do_setup do
    random = :rand.uniform(1_000_000_000)
    db_name = "/tmp/nodetest.#{random}"
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

  test "Sole new node transitions to leader", context do
    {:ok, pid} = Erix.Node.start_link(Erix.LevelDB, context[:db_name], context[:node_name], 20)

    Process.sleep(300)

    assert Process.alive?(pid)
    assert Process.registered() |> Enum.any?(fn(n) -> n == context[:node_name] end)
    state = Erix.Server.__fortest__getstate(context[:node_name])
    assert state.state == :leader
    assert state.current_time > 10
  end

  test "Three nodes elect a leader" do
    contexts = for _ <- 1..3, do: do_setup()
    pids = contexts |> Enum.map(fn(context) ->
      {:ok, pid} = Erix.Node.start_link(Erix.LevelDB, context[:db_name], context[:node_name], 20)
      pid
    end)
    # Pear up
    names = contexts |> Enum.map(fn(context) -> context[:node_name] end)
    Erix.Server.add_peer(Enum.at(names, 0), {Erix.Server, Enum.at(names, 1)})
    Erix.Server.add_peer(Enum.at(names, 0), {Erix.Server, Enum.at(names, 2)})

    Process.sleep(500) # 25 ticks should be enough to get a leader

    pids |> Enum.map(fn(pid) ->
      assert Process.alive?(pid)
    end)
    {f, l} = contexts |> Enum.reduce({0, 0}, fn(context, {f, l}) ->
      state = Erix.Server.__fortest__getstate(context[:node_name])
      if state.state == :leader, do: {f, l + 1}, else: {f + 1, l}
    end)
    assert {f, l} == {2, 1}
  end
end
