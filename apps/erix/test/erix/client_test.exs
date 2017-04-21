defmodule Erix.ClientTest.Common do
  use ExUnit.Case, async: true
  def do_setup do
    random = :rand.uniform(1_000_000_000)
    db_name = "/tmp/clienttest.#{random}"
    node_name = :"node.#{random}"
    on_exit fn ->
      File.rm_rf!(db_name)
    end
    [db_name: db_name, node_name: node_name]
  end
end
defmodule Erix.ClientTest.One do
  use ExUnit.Case, async: true
  require Logger
  @moduletag :integration
  setup do
    Erix.ClientTest.Common.do_setup()
  end

  test "client starts as part of node startup", context do
    {:ok, _pid} = Erix.Node.start_link(Erix.LevelDB, context[:db_name], context[:node_name], 20)
    Process.sleep(300) # Make the node leader

    client_name = Erix.Node.client_name(context[:node_name])
    assert Process.registered() |> Enum.any?(fn(n) -> n == client_name end)
  end

  test "Client starts with empty data", context do
    {:ok, pid} = Erix.Client.start_link(context[:node_name])

    assert Erix.Client.count(pid) == 0
  end

end
defmodule Erix.ClientTest.Two do
  use ExUnit.Case, async: true
  require Logger
  @moduletag :integration
  setup do
    Erix.ClientTest.Common.do_setup()
  end

  test "Client writes go through the leader", context do
    {:ok, _pid} = Erix.Node.start_link(Erix.LevelDB, context[:db_name], context[:node_name], 20)
    Process.sleep(300) # Make the node leader
    client_name = Erix.Node.client_name(context[:node_name])

    # This will not return until it is done.
    Erix.Client.put(client_name, :foo, :bar)

    # Test that the client has the confirmed data back
    assert Erix.Client.count(client_name) == 1
    assert Erix.Client.get(client_name, :foo) == :bar

    # ..and that the leader has the data as well in its committed log (minor TODO)
  end

end
defmodule Erix.ClientTest.Three do
  use ExUnit.Case, async: true
  require Logger
  @moduletag :integration

  test "Three nodes keep their clients in sync" do
    contexts = for _ <- 1..3, do: Erix.ClientTest.Common.do_setup()
    contexts |> Enum.map(fn(context) ->
      {:ok, _pid} = Erix.Node.start_link(Erix.LevelDB,
                      context[:db_name], context[:node_name], 20)
    end)
    # Pear up
    names = contexts |> Enum.map(fn(context) -> context[:node_name] end)
    peers = names |> Enum.map(fn(name) -> Erix.Server.__fortest__getpeer(name) end)
    Erix.Server.add_peer(Enum.at(names, 0), Enum.at(peers, 1))
    Erix.Server.add_peer(Enum.at(names, 0), Enum.at(peers, 2))

    Process.sleep(500) # 25 ticks should be enough to get a leader

    first = Enum.at(contexts, 0)
    client_name = Erix.Node.client_name(first[:node_name])

    Erix.Client.put(client_name, :foo, :bar)

    Process.sleep(100) # Give it some time to propagate

    # Now check all three clients, they should have the state.
    names |> Enum.map(fn(node_name) ->
      client = Erix.Node.client_name(node_name)
      assert Erix.Client.get(client, :foo) == :bar
    end)
  end
end
