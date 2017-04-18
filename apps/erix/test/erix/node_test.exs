defmodule Erix.NodeTest do
  use ExUnit.Case, async: true
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
    # TODO make add_peer return peering info so we only need two links.
    if false do
    Erix.Server.add_peer(Enum.at(pids, 1), Enum.at(pids, 0))
    Erix.Server.add_peer(Enum.at(pids, 0), Enum.at(pids, 1))
    Erix.Server.add_peer(Enum.at(pids, 2), Enum.at(pids, 0))
    Erix.Server.add_peer(Enum.at(pids, 0), Enum.at(pids, 2))
    Erix.Server.add_peer(Enum.at(pids, 1), Enum.at(pids, 2))
    Erix.Server.add_peer(Enum.at(pids, 2), Enum.at(pids, 1))

    Process.sleep(500)

    pids |> Enum.map(fn(pid) ->
      assert Process.alive?(pid)
    end)
    contexts |> Enum.map(fn(context) ->
      state = Erix.Server.__fortest__getstate(context[:node_name])
      IO.puts("node=#{inspect context} state=#{inspect state}")
    end)
    end
  end
end
