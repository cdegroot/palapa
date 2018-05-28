defmodule LifLaf.Node do
  use GenServer

  def start_link(config_mod \\ LifLaf.NodeConfig,
                 elixir_node_mod \\ Node,
                 fs_mod \\ LifLaf.FileSystem) do
    GenServer.start_link(__MODULE__, {config_mod, elixir_node_mod, fs_mod})
  end

  def tick(pid) do
    GenServer.cast(pid, :tick)
  end

  # Server implementation

  def init({config_mod, elixir_node_mod, fs_mod}) do
    config = config_mod.read_config()
    name = String.to_atom(config.id)
    :global.register_name(name, self())
    config.peers
    |> Enum.map(fn({_id, node}) -> elixir_node_mod.connect(node) end)
    root_hash = fs_mod.open()
    state = config
    |> Map.put(:fs_mod, fs_mod)
    |> Map.put(:elixir_node_mod, elixir_node_mod)
    |> Map.put(:root_hash, root_hash)
    {:ok, state}
  end

  def handle_cast(:tick, state) do
    # There are multiple ways to skin this cat.
    # What would be the easiest one to test?
    state.peers
    |> Enum.map(fn({id, _node}) ->
      :global.send(String.to_atom(id), {:ping, self(), state.id, state.root_hash})
    end)
    {:noreply, state}
  end
end
