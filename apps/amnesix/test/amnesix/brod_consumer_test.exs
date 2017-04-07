defmodule Amnesix.BrodConsumerTest do
  use ExUnit.Case, async: true
  @moduletag :integration

  alias Amnesix.BrodConsumer

  defmodule MockWorkersSupervisor do
    @behaviour Amnesix.WorkersSupervisor.Behaviour
    def load_partitions(pid, partitions) do
      send(pid, {:load, partitions})
      []
    end
    def remove_partitions(pid) do
      send(pid, :remove)
      :ok
    end
    def process_message(_pid, _part, _key, _value) do
      {:error, "Unexpected process_message call"}
    end
  end

  test "subscriber hooks up to Brod and gets partitions assigned" do
    {:ok, _pid} = BrodConsumer.start_link({MockWorkersSupervisor, self()})
    Process.sleep(500)
    assert_received :remove
    assert_received {:load, [0, 1]}
  end

  test "post load, partitions are subscribed to and messages flow" do
    {:ok, _pid} = BrodConsumer.start_link({MockWorkersSupervisor, self()})
    Process.sleep(500)
  end
end
