defmodule Amnesix do
  @moduledoc """
  Documentation for Amnesix.
  """

  @doc """
  Calculate the partition for a given key
  """
  def partition_for(key, total_partitions) do
    hash = :erlang.crc32(key)
    rem(hash, total_partitions)
  end
end
