defmodule Amnesix.KafkaPersisterTest do
  use ExUnit.Case, async: true
  @moduletag :integration
  alias Amnesix.KafkaPersister

  test "Round-tripping data through kafka works" do
    {:ok, persister} = KafkaPersister.start_link()
    some_map = %{"foo" => {12345, {Amnesix.SomeModule, :somefunction, [1, :rand.uniform()]}}}
    {:ok, state_agent} = Agent.start_link(fn -> %{} end)
    :ok = KafkaPersister.persist(persister, "654", some_map)
    my_partitions = [0, 1]
    KafkaPersister.load(persister, my_partitions, fn(key, value) ->
      Agent.update(state_agent, fn(cur) -> Map.put(cur, key, value) end)
    end)
    end_map = Agent.get(state_agent, fn(state) -> Map.get(state, "654") end)
    assert end_map == some_map
  end
end
