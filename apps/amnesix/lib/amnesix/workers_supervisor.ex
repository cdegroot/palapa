defmodule Amnesix.WorkersSupervisor do
  @moduledoc """
  This module is responsible for setting up the correct tree
  of partition workers based on assignments received from the
  consumer.
  """

  defmodule State, do: defstruct [:persister_mod, :persister_pid, :router_state,
                                  :partition_count]
  alias Amnesix.{RoutingSupervisor, PartitionWorker}

  use GenServer

  def start_link(persister = {_mod, _pid}, partition_worker_module) do
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

  def init({persister = {persister_mod, persister_pid}, partition_count,
            partition_worker_module}) do
    spec = Supervisor.Spec.worker(partition_worker_module,
      [[persister, partition_count]], restart: :transient)
    router_state = RoutingSupervisor.setup(spec, partition_worker_module)
    {:ok, %State{persister_mod: persister_mod, persister_pid: persister_pid,
                 router_state: router_state, partition_count: partition_count}}
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
    {:ok, {worker_mod, worker_pid}, router_state} = RoutingSupervisor.pid_of(state.router_state, partition)
    ans = worker_mod.process_message(worker_pid, key, value)
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
    state.persister_mod.load(state.persister_pid, partitions, fn(key, value) ->
      partition = Amnesix.partition_for(key, partition_count)
      {:ok, {worker_mod, worker_pid}, _router_state} = RoutingSupervisor.pid_of(state.router_state, partition)
      worker_mod.load(worker_pid, key, value)
    end)
    for part <- partitions do
      {:ok, {worker_mod, worker_pid}, _router_state} = RoutingSupervisor.pid_of(state.router_state, part)
      worker_mod.complete_load(worker_pid)
    end
  end
end
