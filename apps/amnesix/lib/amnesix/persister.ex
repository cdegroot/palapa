defmodule Amnesix.Persister do
  @moduledoc """
  An interface and mock implementation for persistence. The
  only two tasks of the module are to persist individual
  worker's states and to replay states.
  """
  use Simpler.Interface

  @type load_callback :: (() -> any)

  @doc """
  Persist an item.
  """
  defmethod persist(pid :: pid, key :: String.t, data :: Map.t) :: :ok

  @doc """
  Load data from Kafka. Arguments of note:

  * `parts` is the array of partitions assigned to this node. These partitions will
  be processed.
  * `callback_fn` is a function that will get the key/value pairs read.

  This function will block the genserver until everything is processed. This is by
  design - reading is a one-time action that should be done before processing starts. All
  partitions are processed in parallel, so overpartition to speed up start times.
  """
  defmethod load(pid :: pid, partitions :: [integer], callback_fn :: load_callback) :: :ok
end
