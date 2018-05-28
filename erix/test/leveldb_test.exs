defmodule Erix.LevelDBTest do
  use ExUnit.Case, async: true

  alias Erix.Server.PersistentState

  @current_term_key Erix.LevelDB._current_term_key()
  @voted_key        Erix.LevelDB._voted_key()
  @last_offset_key  Erix.LevelDB._last_offset_key()
  @node_uuid_key    Erix.LevelDB._node_uuid_key()

  setup do
    name = "/tmp/erix_leveldb_test.#{:rand.uniform(1_000_000_000)}"
    {:ok, db} = Exleveldb.open(name)
    on_exit fn ->
      Exleveldb.close(db)
      File.rm_rf!(name)
    end
    [db: db, name: name]
  end

  defp state_and_db_from_context(context) do
    db = context[:db]
    state = %Erix.Server.State{}
    persistence_ref = {Erix.LevelDB, db}
    state = PersistentState._set_persister(persistence_ref, state)
    {db, state}
  end

  test "Current term returns 0 on an empty database", context do
    {_, state} = state_and_db_from_context(context)

    assert 0 == PersistentState.current_term(state)
  end

  test "Current term correctly read from database", context do
    {db, state} = state_and_db_from_context(context)
    Exleveldb.put(db, @current_term_key, << 42 :: size(64) >>)

    assert 42 == PersistentState.current_term(state)
  end

  test "Current term correctly written to the database", context do
    {db, state} = state_and_db_from_context(context)

    PersistentState.set_current_term(524, state)

    assert {:ok, << 524 :: size(64) >>} == Exleveldb.get(db, @current_term_key)
  end

  test "Voted for returns 0 on an empty database", context do
    {_, state} = state_and_db_from_context(context)

    assert nil == PersistentState.voted_for(state)
  end

  test "Voted for correctly read from database", context do
    {db, state} = state_and_db_from_context(context)
    ref = {__MODULE__, self()}
    Exleveldb.put(db, @voted_key, :erlang.term_to_binary(ref))

    assert ref == PersistentState.voted_for(state)
  end

  test "Voted for correctly written to database", context do
    {db, state} = state_and_db_from_context(context)
    ref = {__MODULE__, self()}

    PersistentState.set_voted_for(ref, state)

    {:ok, bytes} = Exleveldb.get(db, @voted_key)
    assert ref == :erlang.binary_to_term(bytes)
  end

  test "Node UUID returns nil on an empty database", context do
    {_, state} = state_and_db_from_context(context)

    assert nil == PersistentState.node_uuid(state)
  end

  test "Node UUID correctly written to database", context do
    {db, state} = state_and_db_from_context(context)
    uuid = Erix.unique_id()

    PersistentState.set_node_uuid(uuid, state)

    {:ok, uuid_bytes} = Exleveldb.get(db, @node_uuid_key)
    assert uuid_bytes == uuid
  end

  test "Log last offset returns 0 on an empty database", context do
    {_, state} = state_and_db_from_context(context)

    assert 0 == PersistentState.log_last_offset(state)
  end

  test "Log last offset correctly read from database", context do
    {db, state} = state_and_db_from_context(context)
    Exleveldb.put(db, @last_offset_key, << 1234 :: size(64) >>)

    assert 1234 == PersistentState.log_last_offset(state)
  end

  test "Log at returns nil on an empty database for any offset", context do
    {_, state} = state_and_db_from_context(context)

    for i <- 1..10 do
      assert {0, nil} == PersistentState.log_at(i, state)
    end
  end

  test "Append entries on an empty database", context do
    {db, state} = state_and_db_from_context(context)

    PersistentState.append_entries_to_log(1, [{2, "foo"}, {3, :yay}], state)

    {:ok, binary} = Exleveldb.get(db, << 1 :: size(64) >>)
    assert {2, "foo"} == :erlang.binary_to_term(binary)
    {:ok, binary} = Exleveldb.get(db, << 2 :: size(64) >>)
    assert {3, :yay} == :erlang.binary_to_term(binary)
    assert 2 == PersistentState.log_last_offset(state)
  end

  test "Log at after appending", context do
    {_, state} = state_and_db_from_context(context)

    PersistentState.append_entries_to_log(1, [{2, "foo"}, {3, :yay}], state)

    assert {3, :yay} == PersistentState.log_at(2, state)
  end

  test "Log from on an empty database", context do
    {_, state} = state_and_db_from_context(context)

    assert [] == PersistentState.log_from(3, state)
  end

  test "A couple of overwriting append entries and then log_from", context do
    {_, state} = state_and_db_from_context(context)

    PersistentState.append_entries_to_log(1, [{2, "foo"}, {3, :yay}], state)
    PersistentState.append_entries_to_log(2, [{3, "var"}, {3, "stuff"}, {3, :oops}], state)
    assert [{2, "foo"}, {3, "var"}, {3, "stuff"}, {3, :oops}] == PersistentState.log_from(1, state)
    assert [{3, "stuff"}, {3, :oops}] == PersistentState.log_from(3, state)

    assert 4 == PersistentState.log_last_offset(state)
  end
end
