defmodule RegistryTest do
  use ExUnit.Case, async: true
  alias ECS.{Entity, Registry}
  alias ECS.Components.PositionComponent

  test "entities register themselves by their components in a registry" do
    {:ok, registry} = Registry.new(:registrytest_1)
    entity_one = Entity.new([], registry)
    entity_two = Entity.new([PositionComponent.new([x: 10, y: 20])], registry)

    entities_with_registry = Registry.get_all_for_component(registry, :registry)
    assert Enum.sort(entities_with_registry) == [entity_one, entity_two]
    entities_with_position = Registry.get_all_for_component(registry, :position)
    assert entities_with_position == [entity_two]
  end

  test "when an entity gets a new component, it updates itself" do
    {:ok, registry} = Registry.new(:registrytest_2)

    entity = Entity.new([], registry)
    assert Registry.get_all_for_component(registry, :position) == []

    Entity.set_component(entity, PositionComponent.new([x: 10, y: 20]))
    Process.sleep(1)
    assert Registry.get_all_for_component(registry, :position) == [entity]
  end

  test "when an entity loses a component, it updates itself" do
    {:ok, registry} = Registry.new(:registrytest_3)

    entity = Entity.new([PositionComponent.new([x: 10, y: 20])], registry)
    assert Registry.get_all_for_component(registry, :position) == [entity]

    Entity.remove_component(entity, :position)
    Process.sleep(1)
    assert Registry.get_all_for_component(registry, :position) == []
  end

  test "multiple queries can be made in one go" do
    {:ok, registry} = Registry.new(:registrytest_4)
    one = Entity.new([
      AgeComponent.new([value: 22])],
    registry)
    two = Entity.new([
      AgeComponent.new([value: 10]),
      PositionComponent.new([x: 10, y: 20])],
    registry)

    found_components = Registry.get_all_for_components(registry, [:position, :age])
    assert 2 == length(found_components)
    assert [two] == hd(found_components)
    assert [one, two] == Enum.sort(hd(tl(found_components)))
  end
end
