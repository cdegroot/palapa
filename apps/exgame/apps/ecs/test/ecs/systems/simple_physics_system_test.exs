defmodule SimplePhysicsSystemTest do
  use ExUnit.Case
  alias ECS.Entity
  alias ECS.Components.{PositionComponent, CollidableComponent, ColliderComponent}
  alias ECS.Systems.SimplePhysicsSystem

  test "Collision detection works" do
    # Wall one and two intersect but they don't collide.
    # The balls intersect with each other and wall one,
    # and they collide.
    wall_one = Entity.new([
      PositionComponent.new([x: 0, y: 0, z: 0]),
      CollidableComponent.new([h: 10, w: 10, d: 10])
    ])
    wall_two = Entity.new([
      PositionComponent.new([x: 9, y: 9, z: 9]),
      CollidableComponent.new([h: 10, w: 10, d: 10])
    ])
    ball_one = Entity.new([
      PositionComponent.new([x: 1, y: 1, z: 1]),
      ColliderComponent.new([h: 2, d: 2, w: 2])
    ])
    ball_two = Entity.new([
      PositionComponent.new([x: 2, y: 2, z: 2]),
      ColliderComponent.new([h: 2, d: 2, w: 2])
    ])
    collidables = [wall_one, wall_two]
    colliders   = [ball_one, ball_two]
    collissions = SimplePhysicsSystem.calculate_collissions(collidables, colliders)
    assert collissions == [{ball_one, wall_one},
                           {ball_two, wall_one},
                           {ball_one, ball_two}]
  end
end
