defmodule Amnesix.PartitionWorker do
  @moduledoc """
  This module is responsible for handling a partition. It maintains
  the lifecycle of individual key workers and forwards calls to them.
  """

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

  def start_link(persister = {_mod, _pid}, worker_module) do
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
    {:ok, {mod, pid}, router_state} = RoutingSupervisor.pid_of(state.router_state, key)
    mod.load_state(pid, value)
    {:reply, :ok, %State{state | router_state: router_state}}
  end

  def handle_call({:complete_load}, _from, state) do
    RoutingSupervisor.do_all(state.router_state, fn({mod, pid}) ->
      mod.initialization_done(pid)
    end)
    {:reply, :ok, state}
  end

  def handle_call({:process_message, key, value}, _from, state) do
    # TODO structurally the same as :load - refactor?
    {:ok, {mod, pid}, router_state} = RoutingSupervisor.pid_of(state.router_state, key)
    mod.schedule_work(pid, value)
    {:reply, :ok, %State{state | router_state: router_state}}
  end
end
