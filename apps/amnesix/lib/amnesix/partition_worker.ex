defmodule Amnesix.PartitionWorker do
  @moduledoc """
  This module is responsible for handling a partition. It maintains
  the lifecycle of individual key workers and forwards calls to them.
  """

  defmodule Behaviour do
    use Simpler.Interface

    @doc """
    Load the `value` as the initial state for the worker identified by `key`. This
    should complete synchronously so we can do a check on when everything is loaded
    before subscribing workers to the front-end message queue
    """
    defmethod load(pid :: pid, key :: String.t, value :: String.t) :: :ok

    @doc """
    Signals that loading has been completed. This should be forwarded to all
    the key workers.
    """
    defmethod complete_load(pid :: pid) :: :ok

    @doc """
    Process a message (by forwarding it to the correct worker)
    """
    defmethod process_message(pid :: pid, key :: String.t, value :: String.t) :: :ok
  end

  defmodule Implementation do

    @behaviour Behaviour

    require Logger
    alias Amnesix.RoutingSupervisor


    defmodule State do
      defstruct [:persister, :router_state]
    end

    # So here's the lifecycle:
    # - startup:
    #   - load data from the journal (done by workers_supervisor)
    #   - for each item, find a key worker and send it to the worker (method load)
    #   - if no key worker, create one (method load)
    #   - get and forward the complete_load message which toggles us into running.
    # - running:
    #   - subscribed to topic (way up by brod_consumer), handle message
    #     - find key worker, if not available, create one
    #     - forward message to key worker
    #     - ack message

    use GenServer
    alias Amnesix.{RoutingSupervisor, KeyWorker}

    def start_link({persister, worker_module}) do
      GenServer.start_link(__MODULE__, {persister, worker_module})
    end

    def load(pid, key, value) do
      GenServer.call(pid, {:load, key, value})
    end

    def complete_load(pid) do
      GenServer.call(pid, {:complete_load})
    end

    def process_message(pid, key, value) do
      GenServer.call(pid, {:process_message, key, value})
    end

    # Server implementation

    def init({persister, worker_module}) do
      spec = Supervisor.Spec.worker(worker_module, [[persister]], restart: :transient)
      router_state = RoutingSupervisor.setup(spec, worker_module)
      {:ok, %State{router_state: router_state, persister: persister}}
    end

    def handle_call({:load, key, value}, _from, state) do
      {:ok, worker_pid, router_state} = RoutingSupervisor.pid_of(state.router_state, key)
      KeyWorker.Behaviour.load_state(worker_pid, value)
      {:reply, :ok, %State{state | router_state: router_state}}
    end

    def handle_call({:complete_load}, _from, state) do
      RoutingSupervisor.do_all(state.router_state, fn(pid) ->
        KeyWorker.Behaviour.initialization_done(pid)
      end)
      {:reply, :ok, state}
    end

    def handle_call({:process_message, key, value}, _from, state) do
      # TODO structurally the same as :load - refactor?
      {:ok, worker_pid, router_state} = RoutingSupervisor.pid_of(state.router_state, key)
      KeyWorker.Behaviour.schedule_work(worker_pid, value)
      {:reply, :ok, %State{state | router_state: router_state}}
    end
  end
end
