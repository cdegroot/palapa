defmodule Amnesix.PartitionWorkerTest do
  use ExUnit.Case, async: true

  alias Amnesix.PartitionWorker

  defmodule MockPersister do
    @behaviour Amnesix.Persister
    def persist(pid, key, data) do
      flunk "Unexpected call persist(#{inspect pid}, #{inspect key}, #{inspect data})"
    end
    def load(pid, partitions, callback_fn) do
      flunk "Unexpected call load(#{inspect pid}, #{inspect partitions}, #{inspect callback_fn})"
    end
    # The only way we can have our stub worker talk back to the test process
    # is through here... a bit dirty but it'll work
    # TODO cleaner solution? Also happens in workers_supervisor_test
    def tell_test({_module, pid}, stuff) do
      send(pid, stuff)
    end
  end

  defmodule StubKeyWorker do
    use GenServer
    @behaviour Amnesix.KeyWorker.Behaviour
    def start_link([persister], key) do
      GenServer.start_link(__MODULE__, {persister, key})
    end
    def load_state(pid, state) do
      GenServer.call(pid, {:load_state, state})
    end
    def initialization_done(pid) do
      GenServer.call(pid, :initialization_done)
    end
    def schedule_work(pid, work) do
      GenServer.call(pid, {:schedule_work, work})
    end
    def handle_call(msg, _from, state = {persister, key}) do
      MockPersister.tell_test(persister, {:kw, key, msg})
      {:reply, :ok, state}
    end
  end

  test "load routes the key/value to the correct worker" do
    persister = {MockPersister, self()}
    {:ok, partition_worker} = PartitionWorker.Behaviour.start_link(PartitionWorker.Implementation,
      {persister, StubKeyWorker})

    :ok = PartitionWorker.Behaviour.load(partition_worker, "a key", "some initial state")
    :ok = PartitionWorker.Behaviour.load(partition_worker, "another key", "another state")
    :ok = PartitionWorker.Behaviour.load(partition_worker, "a key", "a state, again!")

    assert_received {:kw, "a key", {:load_state, "some initial state"}}
    assert_received {:kw, "another key", {:load_state, "another state"}}
    assert_received {:kw, "a key", {:load_state, "a state, again!"}}
  end

  test "complete_load is forwarded to all workers" do
    persister = {MockPersister, self()}
    {:ok, partition_worker} = PartitionWorker.Behaviour.start_link(PartitionWorker.Implementation,
      {persister, StubKeyWorker})

    # Kick two workers into action
    :ok = PartitionWorker.Behaviour.load(partition_worker, "a key", "some initial state")
    :ok = PartitionWorker.Behaviour.load(partition_worker, "another key", "another state")

    # Send the message
    :ok = PartitionWorker.Behaviour.complete_load(partition_worker)

    assert_received {:kw, "a key", :initialization_done}
    assert_received {:kw, "another key", :initialization_done}
  end

  test "process message is forwarded to the correct worker" do
    persister = {MockPersister, self()}
    {:ok, partition_worker} = PartitionWorker.Behaviour.start_link(PartitionWorker.Implementation,
      {persister, StubKeyWorker})

    :ok = PartitionWorker.Behaviour.process_message(partition_worker, "a key", "a value")

    assert_received {:kw, "a key", {:schedule_work, "a value"}}
  end
end
