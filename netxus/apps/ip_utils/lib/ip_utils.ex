defmodule IpUtils do
  @moduledoc """
  Various IP related utilities.
  """

  @spec ipv4?(String.t | charlist) :: boolean
  def ipv4?(address) do
    family(address) == :ipv4
  end

  @spec ipv6?(String.t | charlist) :: boolean
  def ipv6?(address) do
    family(address) == :ipv6
  end

   @spec ptr(String.t | charlist()) :: list(pos_integer)
  def ptr(address) do
    ptr(address, family(address))
  end
  def ptr(address, :ipv4) do
    {:ok, tuple} = parse(address)
    tuple
    |> Tuple.to_list()
    |> Enum.reverse()
  end
  def ptr(address, :ipv6) do
    use Bitwise
    {:ok, tuple} = parse(address)
    tuple
    |> Tuple.to_list()
    |> Enum.flat_map(fn i ->
      [(i &&& 0xf000) >>> 12,
       (i &&& 0x0f00) >>> 8,
       (i &&& 0x00f0) >>> 4,
       (i &&& 0x000f)]
    end)
    |> Enum.reverse()
  end

  def parse(address) when is_binary(address) do
    :inet.parse_address(String.to_charlist(address))
  end
  def parse(address) when is_list(address) do
    :inet.parse_address(address)
  end
  def parse(_address) do
    nil
  end
  def family(address) when is_tuple(address) do
    elems = Tuple.to_list(address)
    case length(elems) do
      4 -> :ipv4
      8 -> :ipv6
      _ -> nil
    end
  end
  def family(address) do
    case parse(address) do
      {:ok, elems} -> family(elems)
      _ -> nil
    end
  end
end
