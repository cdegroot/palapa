defmodule LifLaf.Node do
  use GenServer

  def start_link(config_mod \\ LifLaf.NodeConfig,
                 node_mod \\ Node) do
    GenServer.start_link(__MODULE__, {config_mod, node_mod})
  end


  # Server implementation

  def init({config_mod, node_mod}) do
    config = config_mod.read_config()
    name = String.to_atom(config.id)
    :global.register_name(name, self())
    config.peers |> Enum.map(fn({_id, node}) -> node_mod.connect(node) end)
    {:ok, config}
  end
end
