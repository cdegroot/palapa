defmodule ComponentTest do
  use ExUnit.Case
  alias ECS.Component
  alias ECS.Components.PositionComponent

  test "a component has a generated new function" do
    default_position = PositionComponent.new
    assert default_position.x == nil
    assert default_position.y == nil

    position = PositionComponent.new([x: 10, y: 20])
    assert position.x == 10
    assert position.y == 20
  end

  test "you can call functions on components" do
    position = PositionComponent.new([x: 10, y: 20])
    new_position = Component.apply(position, :move_down, [10])
    assert new_position == PositionComponent.new([x: 0, y: 20])
  end
end
