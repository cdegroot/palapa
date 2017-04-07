defmodule Amnesix.BrodConsumer do
  @moduledoc """
  The BrodConsumer makes use of Brod's group subscriber functionality
  to receive and monitor partition assignments (to handle setup and
  teardown of workers), and to actually consume and forward messages
  to workers.
  """
  @behaviour :brod_group_member
  use GenServer

  require Logger
  require Record

  alias Amnesix.WorkersSupervisor

  @client_name     :work_consumer
  @group_name      "amnesix_work_consumer" # Do we need this to be configgable?
  @group_config    [offset_commit_policy: :commit_to_kafka_v2,
                    offset_commit_interval_seconds: 5,
                    rejoin_delay_seconds: 5,
                    max_rejoin_attempts:  10]

  # I'm still not sure that this is actually useful...
  Record.defrecord :kafka_message_set, Record.extract(:kafka_message_set,
                                                     from: "deps/brod/include/brod.hrl")

  defmodule State do
    defstruct [:brokers, :topic, :coordinator, :workers_supervisor,
               :consumers, :generation_id]
  end

  @doc """
  Start the group subscriber. The `workers_supervisor` is a supervisor
  that is responsible for setting up a worker hierarchy for the assigned
  partitions.
  """
  def start_link(workers_supervisor) do
    brokers = Application.get_env(:amnesix, :brokers)
    work_topic = Application.get_env(:amnesix, :work_topic)
    GenServer.start_link(__MODULE__, {brokers, work_topic, workers_supervisor})
  end

  # GenServer callbacks

  def init({brokers, topic, workers_supervisor}) do
    :ok = :brod.start_client(brokers, @client_name, [])
    {:ok, pid} = :brod_group_coordinator.start_link(
      @client_name, @group_name, [topic], @group_config,
      __MODULE__, self())
    state = %State{brokers: brokers, topic: topic, coordinator: pid,
                   workers_supervisor: workers_supervisor,
                  consumers: []}
    {:ok, state}
  end

  def handle_call({:assignments_revoked}, _from, state) do
    WorkersSupervisor.Behaviour.remove_partitions(state.workers_supervisor)
    {:reply, :ok, state}
  end

  def handle_cast({:assignments_received, partition_offsets, generation_id}, state) do
    # TODO some test coverage on the subscribing
    Logger.info("In genserver assignment received #{inspect partition_offsets}")
    # OK, we have a list of partitions we are responsible for. Have the
    # workers supervisor start the workers.
    # TODO do we need to have a consumer config? ---------v
    :ok = :brod.start_consumer(@client_name, state.topic, [])
    partitions = for {partition, _offset} <- partition_offsets, do: partition
    WorkersSupervisor.Behaviour.load_partitions(state.workers_supervisor, partitions)
    # Subscribe to all the partitions.
    consumers = partition_offsets
    |> subscribe_consumers(state.topic, state.consumers)
    |> Map.new
    {:noreply, %State{state | generation_id: generation_id, consumers: consumers}}
  end

  def handle_info({_consumer_pid, msg_set = kafka_message_set()}, state) do
    # TODO some test coverage when this works.
    # Receive a message set. Send it off to the workers and ack when done. We
    # do this all synchronously, we can worry about performance later.
    partition = kafka_message_set(msg_set, :partition)
    msgs = kafka_message_set(msg_set, :messages)
    # 1. Process the messages
    offsets = for {:kafka_message, offset, _magic_byte, _attributes, key, value, _crc} <- msgs do
      process_message(partition, key, value, state)
      offset
    end
    # 2. Ack the message set by acking the last offset. We ack twice:
    #    1. to the group coordinator so it can be committed out
    #    2. to the consumer so we can get moar data
    last_offset = offsets |> Enum.reverse |> hd
    consumer = Map.get(state.consumers, partition)
    :ok = :brod.consume_ack(consumer, last_offset)
    :ok = :brod_group_coordinator.ack(state.coordinator, state.generation_id, state.topic,
                                      partition, last_offset)
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    Logger.info("Brod consumer down pid = #{inspect pid}")
    {partition, _} = Enum.find(state.consumers, fn({k, v}) -> v == pid end)
    consumers = Map.delete(state.consumers, partition)
    # TODO what now? brod_group_subscriber basically just marks a consumer as down...
    {:noreply, %State{state | consumers: consumers}}
  end

  # brod_group_member callbacks

  def assignments_received(pid, _member_id, generation_id, brod_received_assignments) do
    partition_offsets = brod_received_assignments
    |> Enum.map(fn({:brod_received_assignment, _topic, partition, offset}) ->
      {partition, offset}
    end)
    Logger.info("Received assignments for #{inspect partition_offsets}")
    :ok = GenServer.cast(pid, {:assignments_received, partition_offsets, generation_id})
  end

  # Called before group re-balancing, the member should call
  # brod:unsubscribe/3 to unsubscribe from all currently subscribed partitions.
  #
  def assignments_revoked(pid) do
    Logger.info("Assignments revoked on #{inspect pid}")
    :ok = GenServer.call(pid, {:assignments_revoked})
  end

  # Unused (for now) brod_group_member callbacks
  def assign_partitions(_pid, _members, _topic_partitions) do
    Logger.error("Unexpected assign_partitions call!")
    :error
  end
  def get_committed_offsets(_pid, _topic_partitions) do
    Logger.error("Unexpected get_committed_offsets call!")
  end

  # Private stuff

  # Once in a while you can do a recursive thingy ;-)
  defp subscribe_consumers([], _topic, consumers), do: consumers
  defp subscribe_consumers([{partition, offset} | rest], topic, consumers) do
    consumer = subscribe_consumer(partition, offset, topic)
    subscribe_consumers(rest, topic, [consumer | consumers])
  end
  defp subscribe_consumer(partition, offset, topic) do
    Logger.debug("Subscribe to #{partition} from #{inspect offset}")
    opts = if offset == :undefined, do: [], else: [begin_offset: offset]
    {:ok, pid} = :brod.subscribe(@client_name, self(), topic, partition, opts)
    Process.monitor(pid)
    {partition, pid}
  end

  defp process_message(partition, key, value, state) do
    :ok = WorkersSupervisor.Behaviour.process_message(state.workers_supervisor, partition, key, value)
  end

end
