defmodule VelocityComponentTest do
  use ExUnit.Case
  alias ECS.Entity
  alias ECS.Components.{PositionComponent, VelocityComponent}

  test "a tick updates the postion by one velocity step" do
    entity = Entity.new([
      VelocityComponent.new([vx: 5, vy: 4, vz: 3]),
      PositionComponent.new([x: 10, y: 20, z: 30])])

    VelocityComponent.tick(entity)

    position =  Entity.get_component(entity, :position)
    assert position.x == 15
    assert position.y == 24
    assert position.z == 33
  end

  test "polar construction results in the correct velocity" do
    velocity = VelocityComponent.from_polar(3, 5.67232)
    assert_in_delta velocity.vx,  2.46, 0.01
    assert_in_delta velocity.vy, -1.72, 0.01
  end
end
