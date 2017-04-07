defmodule Amnesix.WorkersSupervisor do
  @moduledoc """
  This module is responsible for setting up the correct tree
  of partition workers based on assignments received from the
  consumer.
  """

  defmodule Behaviour do
    use Simpler.Interface

    @doc """
    Startup workers for the indicated partitions, then feed them the backlog
    and tell them to start crankin'. We do that all here so we can complete
    the whole thing synchronously before we return, leaving all the workers
    in a state ready to start consuming.
    """
    defmethod load_partitions(pid :: pid, partitions :: [integer]) :: [pid]

    @doc """
    Remove all partitions.
    """
    defmethod remove_partitions(pid :: pid) :: :ok

    @doc """
    Process a message by sending it on to the correct partition
    """
    defmethod process_message(pid :: pid, partition :: integer, key :: String.t, value :: String.t) :: :ok
  end

  defmodule Implementation do
    @moduledoc """
    Default implementation of `Amnesix.WorkersSupervisor.Behaviour`
    """
    defmodule State, do: defstruct [:persister, :router_state, :partition_count]
    alias Amnesix.{RoutingSupervisor, PartitionWorker}

    use GenServer

    def start_link({persister, partition_worker_module}) do
      partition_count = Application.get_env(:amnesix, :partitions)
      GenServer.start_link(__MODULE__, {persister, partition_count, partition_worker_module})
    end

    def load_partitions(pid, partitions) do
      GenServer.call(pid, {:load_partitions, partitions})
    end

    def remove_partitions(pid) do
      GenServer.call(pid, :remove_partitions)
    end

    def process_message(pid, partition, key, value) do
      GenServer.call(pid, {:process_message, partition, key, value})
    end

    # Implementation

    def init({persister, partition_count, partition_worker_module}) do
      spec = Supervisor.Spec.worker(partition_worker_module,
        [[persister, partition_count]], restart: :transient)
      router_state = RoutingSupervisor.setup(spec, partition_worker_module)
      {:ok, %State{persister: persister, router_state: router_state,
                   partition_count: partition_count}}
    end

    def handle_call({:load_partitions, partitions}, _from, state) do
      state =  create_children(partitions, state)
      load_children(state.partition_count, partitions, state)
      {:reply, :ok, state}
    end

    def handle_call(:remove_partitions, _from, state) do
      router_state = RoutingSupervisor.shutdown(state.router_state)
      {:reply, :ok, %State{ state | router_state: router_state}}
    end

    def handle_call({:process_message, partition, key, value}, _from, state) do
      {:ok, worker, router_state} = RoutingSupervisor.pid_of(state.router_state, partition)
      ans = PartitionWorker.Behaviour.process_message(worker, key, value)
      {:reply, ans, %State{state | router_state: router_state}}
    end

    # Private functions

    defp create_children(partitions, state) do
      # Create children by calling the routing supervisor for each key
      router_state = partitions
      |> Enum.reduce(state.router_state, fn(part, router_state) ->
        {:ok, _pid, new_state} = RoutingSupervisor.pid_of(router_state, part)
        new_state
      end)
      %State{state | router_state: router_state}
    end

    defp load_children(partition_count, partitions, state) do
      # Send a load, then a complete_load to every partition worker
      Amnesix.Persister.load(state.persister, partitions, fn(key, value) ->
        partition = Amnesix.partition_for(key, partition_count)
        {:ok, worker, _router_state} = RoutingSupervisor.pid_of(state.router_state, partition)
        PartitionWorker.Behaviour.load(worker, key, value)
      end)
      for part <- partitions do
        {:ok, worker, _router_state} = RoutingSupervisor.pid_of(state.router_state, part)
        PartitionWorker.Behaviour.complete_load(worker)
      end
    end
  end
end
