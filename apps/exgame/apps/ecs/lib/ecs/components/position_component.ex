defmodule ECS.Components.PositionComponent do
  @moduledoc """
  Standard position component. The coordinate system
  is x (up, down); y (right, left), z (front, back) where
  the first term is the positive direction in each case.

  In case of 2D, there are versions of most functions that
  have no z component, or ignore the z component.
  """
  import ECS.Component
  alias ECS.Entity

  component_fields [:x, :y, :z]

  def move_to(entity_pid, x, y, z \\ 0) do
    new = %ECS.Components.PositionComponent{x: x, y: y, z: z}
    Entity.set_component(entity_pid, new)
  end

  # An update utility function. Just used by a test now.
  def move_down(position, delta_x) do
    %ECS.Components.PositionComponent{position | x: position.x - delta_x}
  end
end
