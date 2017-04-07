defmodule EntityTest do
  use ExUnit.Case
  alias ECS.Components.PositionComponent
  alias ECS.Entity

  test "an entity gets a unique ID" do
    entity_one = Entity.new()
    assert Entity.id(entity_one) != nil
    entity_two = Entity.new()
    assert Entity.id(entity_two) != Entity.id(entity_one)
  end

  test "an entity can have multiple components" do
    entity = Entity.new([
      AgeComponent.new([value: 21]),
      PositionComponent.new([x: 10, y: 20])])
    assert Entity.get_component(entity, :age).value == 21
    assert Entity.get_component(entity, :position).x == 10
    assert Entity.get_component(entity, :position).y == 20
  end

  test "an entity has mutable state" do
    entity = Entity.new([
      PositionComponent.new([x: 10, y: 20])])
    PositionComponent.move_to(entity, 20, 30)
    assert Entity.get_component(entity, :position).x == 20
    assert Entity.get_component(entity, :position).y == 30
  end

  test "an entity can update itself" do
    entity = Entity.new([
      PositionComponent.new([x: 10, y: 20])])
    gravity = fn position ->
      PositionComponent.move_down(position, 1)
    end
    Entity.update_component(entity, :position, gravity)
    Process.sleep(1)
    assert Entity.get_component(entity, :position).x == 9
  end

  test "multiple components can be fetched at once" do
    entity = Entity.new([
      AgeComponent.new([value: 21]),
      PositionComponent.new([x: 10, y: 20])])
    components = Entity.get_components(entity, [:age, :position])
    age = Enum.at(components, 0)
    position = Enum.at(components, 1)
    assert age == AgeComponent.new([value: 21])
    assert position == PositionComponent.new([x: 10, y: 20])
  end
end
