defmodule Amnesix.BrodConsumerTest do
  use ExUnit.Case, async: true
  @moduletag :integration

  alias Amnesix.BrodConsumer
  require Logger

  defmodule MockWorkersSupervisor do
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
    assert_partitions_eventually_load()
  end

  test "post load, partitions are subscribed to and messages flow" do
    {:ok, _pid} = BrodConsumer.start_link({MockWorkersSupervisor, self()})
    # TODO complete this test.
  end

  defp assert_partitions_eventually_load do
    # We can have one or two :remove messages, but then we should get
    # a load.
    receive do
      :remove ->
        Logger.debug("Got remove, retrying")
        assert_partitions_eventually_load()
      {:load, [0, 1]} ->
        Logger.debug("Got load, all good")
        :ok
    after
      10_000 -> flunk "Timeout waiting for partition load"
    end
  end
end
