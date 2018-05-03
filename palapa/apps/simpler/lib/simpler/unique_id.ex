defmodule Simpler.UniqueId do
  @moduledoc """
  128 bit unique ids without the UUID complexity. And shorter string representation.
  """

  @doc """
  Generate a 128 bit unique id. Uses `:rand.uniform()` so you can seed
  the process if you want to.
  """
  def unique_id do
    use Bitwise
    (((:rand.uniform(4_294_967_296) - 1) <<< 96) |||
     ((:rand.uniform(4_294_967_296) - 1) <<< 64) |||
     ((:rand.uniform(4_294_967_296) - 1) <<< 32) |||
     ((:rand.uniform(4_294_967_296) - 1)))
  end

  @doc """
  Generate a 128 bit unique id in string form. Uses `:rand.uniform()` so you
  can seed the process if you want to
  """
  def unique_id_string do
    unique_id() |> Simpler.UniqueId.to_string()
  end

  @doc """
  Represent a unique id as a string. Basically prints a base36 representation.
  """
  def to_string(id) do
    Integer.to_string(id, 36)
  end

  @doc """
  Converts a string into a binary unique id.
  """
  def from_string(id_string) do
    String.to_integer(id_string, 36)
  end
end
