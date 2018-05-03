defmodule ECS.Components.ColliderComponent do
  @moduledoc """
  Components that can collide. These are meant to be
  active things - players, bullets. Colliders can collide
  with colliders and collidables, but collidables cannot
  collide with collidables as they don't move. This should
  optimize collision detection a bit.
  """
  import ECS.Component

  component_fields [:w, :h, :d]
end
