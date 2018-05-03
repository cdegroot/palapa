defmodule Erix.Node do
  @moduledoc """
  The top level interface to the library is the "node". This will wrap the functionality
  provided by client, server, setup persistence, and start the ticking timer. It also
  handles fun stuff like peer management, node identification, etcetera.
  """

  @default_tick_time_ms 100

  @doc """
  Start a node. The indicated db_module is used for persistence, the db_name is
  passed to that module's `open` method. If there is an empty database, a new
  unique id will be created for the node. It will also register the server under the
  indicated node name so that remote nodes can access us through the `{name, node}`.
  destination. Note that nodes have UUIDs to identify themselves inside the protocol,
  so node names don't need to be unique on the network.
  """
  def start_link(db_module, db_name, node_name \\ :erix, tick_time_ms \\ @default_tick_time_ms) do
    children = [
      Erix.Node.ServerWorker.worker_spec(db_module, db_name, node_name),
      Erix.Node.TimerWorker.worker_spec(tick_time_ms, node_name),
      Erix.Node.ClientWorker.worker_spec(node_name)
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defmodule TimerWorker do
    @moduledoc """
    A wrapper and spec for `Erix.Timer`
    """
    def start_link(tick_time_ms, node_name) do
      fun = fn ->
        Erix.Server.tick(node_name)
      end
      Erix.Timer.start_link(tick_time_ms, fun)
    end

    def worker_spec(tick_time_ms, node_name) do
      import Supervisor.Spec
      worker(__MODULE__, [tick_time_ms, node_name])
    end
  end

  defmodule ServerWorker do
    @moduledoc """
    A wrapper and spec for `Erix.Server`
    """
    def start_link(db_module, db_name, node_name) do
      {:ok, db} = db_module.open(db_name)
      Erix.Server.start_link({db_module, db}, node_name)
    end

    def worker_spec(db_module, db_name, node_name) do
      import Supervisor.Spec
      worker(__MODULE__, [db_module, db_name, node_name])
    end
  end

  defmodule ClientWorker do
    @moduledoc """
    A wrapper and spec for `Erix.Client`
    """
    def start_link(node_name) do
      Erix.Client.start_link(node_name)
    end

    def worker_spec(node_name) do
      import Supervisor.Spec
      worker(__MODULE__, [node_name])
    end
  end

  @doc "Given the node name, construct the client's process name"
  def client_name(node_name) do
    String.to_atom(Atom.to_string(node_name) <> "_client")
  end
end
