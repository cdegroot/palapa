defmodule ECS.Components.CollidableComponent do
  @moduledoc """
  Components one can collide with. These are meant to be
  passive things - walls, floors. Colliders can collide
  with colliders and collidables, but collidables cannot
  collide with collidables as they don't move. This should
  optimize collision detection a bit.
  """
  import ECS.Component

  component_fields [:h, :w, :d, :tag]
end
