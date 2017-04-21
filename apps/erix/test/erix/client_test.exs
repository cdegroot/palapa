defmodule Erix.ClientTest.Common do
  use ExUnit.Case, async: true
  def setup do
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
    Erix.ClientTest.Common.setup()
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

  test "Client writes go through the leader", context do
    {:ok, _pid} = Erix.Node.start_link(Erix.LevelDB, context[:db_name], context[:node_name], 20)
    Process.sleep(300) # Make the node leader
    client_name = Erix.Node.client_name(context[:node_name])

    # This will not return until it is done.
    Erix.Client.put(client_name, :foo, :bar)

    # Test that the client has the confirmed data back
    assert Erix.Client.count(client_name) == 1

    # ..and that the leader has the data as well in its committed log
  end

  # TODO multiple clients are kept in sync. Setup a three node cluster, execute
  # a command, check that state is in sync.
end
