defmodule RegistryTest do
  use ExUnit.Case, async: true
  alias ECS.{Entity, Registry}
  alias ECS.Components.PositionComponent

  test "entities register themselves by their components in a registry" do
    {:ok, registry} = Registry.new
    entity_one = Entity.new([], registry)
    entity_two = Entity.new([PositionComponent.new([x: 10, y: 20])], registry)

    entities_with_registry = Registry.get_all_for_component(registry, :registry)
    assert entities_with_registry == [entity_two, entity_one]
    entities_with_position = Registry.get_all_for_component(registry, :position)
    assert entities_with_position == [entity_two]
  end

  test "when an entity gets a new component, it updates itself" do
    {:ok, registry} = Registry.new

    entity = Entity.new([], registry)
    assert Registry.get_all_for_component(registry, :position) == []

    Entity.set_component(entity, PositionComponent.new([x: 10, y: 20]))
    Process.sleep(1)
    assert Registry.get_all_for_component(registry, :position) == [entity]
  end

  test "when an entity loses a component, it updates itself" do
    {:ok, registry} = Registry.new

    entity = Entity.new([PositionComponent.new([x: 10, y: 20])], registry)
    assert Registry.get_all_for_component(registry, :position) == [entity]

    Entity.remove_component(entity, :position)
    Process.sleep(1)
    assert Registry.get_all_for_component(registry, :position) == []
  end

  test "multiple queries can be made in one go" do
    {:ok, registry} = Registry.new
    one = Entity.new([
      AgeComponent.new([value: 22])],
    registry)
    two = Entity.new([
      AgeComponent.new([value: 10]),
      PositionComponent.new([x: 10, y: 20])],
    registry)

    found_components = Registry.get_all_for_components(registry, [:position, :age])
    assert [[two], [two, one]] == found_components
  end
end
