defmodule Erix.ClientTest do
  use ExUnit.Case, async: true
  require Logger
  @moduletag :integration
  setup do
    Erix.NodeTest.Common.do_setup()
  end

  test "Basic client-to-leader functionality", context do
    {:ok, pid} = Erix.Node.start_link(Erix.LevelDB, context[:db_name], context[:node_name], 20)
    Process.sleep(300) # Make the node leader


  end
end
