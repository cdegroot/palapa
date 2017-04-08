defmodule Amnesix.WorkersSupervisorTest do
  use ExUnit.Case, async: true

  alias Amnesix.WorkersSupervisor

  defmodule MockPersister do
    def persist(_pid, _key, _data) do
      :ok
    end
    def load(pid, partitions, callback_fn) do
      assert is_pid(pid)
      assert partitions == [0, 1]
      callback_fn.("key one", "value one")
      callback_fn.("key two", "value two")
      :ok
    end
    # The only way we can have our stub worker talk back to the test process
    # is through here... a bit dirty but it'll worker
    def tell_test({_module, pid}, stuff) do
      send(pid, stuff)
    end
  end
  defmodule StubPartitionWorker do
    use GenServer
    def start_link([persister, partitions], partition) do
      GenServer.start_link(__MODULE__, {persister, partitions, partition})
    end
    def load(pid, key, value) do
      GenServer.call(pid, {:load, key, value})
    end
    def complete_load(pid) do
      GenServer.call(pid, {:complete_load})
      :ok
    end
    def process_message(pid, key, value) do
      GenServer.call(pid, {:process_message, key, value})
      :ok
    end
    def handle_call(msg, _from, state = {persister, _, partition}) do
      MockPersister.tell_test(persister, {:pw, partition, msg} )
      {:reply, :ok, state}
    end
  end

  test "New setup calls load and complete_load on all partitions" do
    persister = {MockPersister, self()}

    {:ok, workers_supervisor} = WorkersSupervisor.start_link(persister, StubPartitionWorker)

    WorkersSupervisor.load_partitions(workers_supervisor, [0, 1])

    assert_received {:pw, 0, {:load, "key two", "value two"}}
    assert_received {:pw, 1, {:load, "key one", "value one"}}
    assert_received {:pw, 0, {:complete_load}}
    assert_received {:pw, 1, {:complete_load}}
  end

  test "When process_message is called, the correct worker gets a message" do
    persister = {MockPersister, self()}

    {:ok, workers_supervisor} = WorkersSupervisor.start_link(persister, StubPartitionWorker)

    # Note that we have the partition here, so whatever the partition is, a
    # worker will be created and receive the message
    WorkersSupervisor.process_message(workers_supervisor, 42, "key", "val")

    assert_received {:pw, 42, {:process_message, "key", "val"}}
  end
end
