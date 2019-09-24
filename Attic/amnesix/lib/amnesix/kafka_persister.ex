defmodule Amnesix.KafkaPersister do
  @moduledoc """
  Module that persists worker states using Kafka compacted topics
  """

  # TODO make all this configurable
  @client_name :amnesix_journal_client

  defmodule State do
    defstruct [:brokers, :journal_topic, :partitions]
  end

  use GenServer
  require Logger

  @doc """
  Creates a new persister
  """
  def start_link do
    brokers = Application.get_env(:amnesix, :brokers)
    journal_topic = Application.get_env(:amnesix, :journal_topic)
    partitions = Application.get_env(:amnesix, :partitions)
    GenServer.start_link(__MODULE__, {brokers, journal_topic, partitions})
  end

  @doc """
  Persist a key/value pair
  """
  def persist(pid, key, value) do
    GenServer.call(pid, {:persist, key, value})
  end

  @doc """
  Load all data (key/value pairs) from the indicated partitions and call the
  callback_fn with each k/v pair.
  """
  def load(pid, parts, callback_fn) do
    GenServer.call(pid, {:load, parts, callback_fn})
  end

  # Server implementation

  def init({brokers, journal_topic, partitions}) do
    :ok = :brod.start_client(brokers, @client_name, [])
    :brod.start_producer(@client_name, journal_topic, [])
    {:ok, %State{brokers: brokers, journal_topic: journal_topic, partitions: partitions}}
  end

  def handle_call({:persist, key, value}, _from, state) do
    :ok = :brod.produce_sync(@client_name, state.journal_topic,
      partition_for(key, state.partitions), key, serialize(value))
    {:reply, :ok, state}
  end

  def handle_call({:load, parts, callback_fn}, _from, state) do
    # We only guarantee ordering per partition. So we can run them
    # in parallel.
    parts
    |> Enum.map(fn(part) -> Task.async(fn -> load_part(part, callback_fn, state) end) end)
    |> Enum.map(&Task.await/1)
    {:reply, :ok, state}
  end

  # Private stuff

  defp load_part(partition, callback_fn, state) do
    {:ok, earliest} = :brod.resolve_offset(state.brokers, state.journal_topic, partition, :earliest)
    {:ok, latest} = :brod.resolve_offset(state.brokers, state.journal_topic, partition, :latest)
    Logger.info("Fetching offests for partition #{partition} from #{inspect earliest} to #{inspect latest}")
    fetch_set(partition, callback_fn, earliest, latest, state)
  end

  defp fetch_set(partition, callback_fn, earliest, latest, state) when earliest < latest do
    Logger.info("fetch set #{inspect state}, #{inspect partition}, #{inspect earliest}")
    {:ok, {_offset, message_set}} = :brod.fetch(state.brokers, state.journal_topic, partition, earliest)
    latest_offset_seen =
      message_set
      |> parse_kafka_message_set
      |> execute_callbacks(callback_fn)
      |> latest_offset_from_list
    # In case we haven't seen it all yet, call ourselves again.
    fetch_set(partition, callback_fn, latest_offset_seen + 1, latest, state)
  end
  defp fetch_set(partition, _callback_fn, _earliest, _latest, _state) do
    Logger.info("All fetched for partition #{partition}")
  end

  defp parse_kafka_message_set(message_set) do
    message_set
    |> Enum.map(fn(message) ->
      {:kafka_message, offset, key, value, _ts_type, _ts, _headers} = message
      {offset, key, value}
    end)
  end

  defp execute_callbacks(offset_key_value_tuples, callback_fn) do
    offset_key_value_tuples
    |> Enum.map(fn({offset, key, value}) ->
      callback_fn.(key, deserialize(value))
      offset
    end)
  end

  defp latest_offset_from_list(offsets) do
    List.last(offsets)
  end

  defp partition_for(key, partitions) do
    rem(:erlang.crc32(key), partitions)
  end

  defp serialize(value) do
    :erlang.term_to_binary(value)
  end
  defp deserialize(value) do
    :erlang.binary_to_term(value)
  end
end
