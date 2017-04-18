defmodule Erix.LevelDB do
  @moduledoc """
  LevelDB implementation of persistent state. We map metadata to keys with
  negative values, and keys 1..n have the commands at the corresponding offsets.
  I have no clue whether this is a smart choice. I also have no clue why I'm
  using LevelDB in the first place. Sue me.
  """
  require Logger

  @behaviour Erix.Server.PersistentState

  @current_term_key       <<-1 :: size(64)>>
  @voted_key              <<-2 :: size(64)>>
  @last_offset_key        <<-3 :: size(64)>>

  @doc "Opens the database with the indicated filename"
  def open(name) do
    Exleveldb.open(name)
  end

  # PersistentState callbacks

  def current_term(db) do
    case Exleveldb.get(db, @current_term_key) do
      :not_found -> 0
      {:ok, << term :: size(64) >>} -> term
    end
  end

  def set_current_term(db, term) do
    :ok = Exleveldb.put(db, @current_term_key, << term :: size(64) >>)
  end

  def voted_for(db) do
    case Exleveldb.get(db, @voted_key) do
      :not_found -> nil
      {:ok, voted_for_bytes} -> :erlang.binary_to_term(voted_for_bytes)
    end
  end

  def set_voted_for(db, voted_for) do
    :ok = Exleveldb.put(db, @voted_key, :erlang.term_to_binary(voted_for))
  end

  def log_last_offset(db) do
    case Exleveldb.get(db, @last_offset_key) do
      :not_found -> 0
      {:ok, << offset :: size(64) >>} -> offset
    end
  end

  def log_at(db, offset) do
    case Exleveldb.get(db, << offset :: size(64)>>) do
      :not_found -> nil
      {:ok, entry_bytes} -> :erlang.binary_to_term(entry_bytes)
    end
  end

  def append_entries_to_log(db, pos, entries) do
    count = length(entries)
    for {offset, entry} <- Enum.zip(0..(count - 1), entries) do
      :ok = Exleveldb.put(db, << offset + pos :: size(64) >>, :erlang.term_to_binary(entry))
    end
    :ok = Exleveldb.put(db, @last_offset_key, << pos + count - 1 :: size(64) >>)
  end

  def log_from(db, pos) do
    last_offset = log_last_offset(db)
    if last_offset >= pos do
      pos..log_last_offset(db)
      |> Enum.map(&(log_at(db, &1)))
    else
      []
    end
  end

  # Accessors for tests

  import Simpler.TestSupport

  deft _current_term_key, do: @current_term_key
  deft _voted_key, do: @voted_key
  deft _last_offset_key, do: @last_offset_key
end
