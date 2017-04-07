defmodule ECS.Components.VelocityComponent do
  @moduledoc """
  Standard velocity component. An entity that has
  velocity must have a position, we're not doing quantum
  physics here. See PositionComponent for the meaning of
  terms and directions of signs.

  Most functions have 2D equivalents that ignore the z
  component.
  """
  require Logger
  import ECS.Component
  alias ECS.Entity
  alias ECS.Components.PositionComponent

  component_fields [:vx, :vy, :vz]

  @doc """
  Make a velocity from an initial polar vector. 2D only at the moment.
  The angle is in radians.
  """
  def from_polar(r, phi) do
    new([vx: r * :math.cos(phi),
         vy: r * :math.sin(phi),
         vz: 0])
  end

  def tick(entity_pid) do
    [velocity, position] = Entity.get_components(entity_pid, [:velocity, :position])
    x = position.x + velocity.vx
    y = position.y + velocity.vy

    nz = if position.z == nil, do: nil, else: position.z + velocity.vz
    # For testing, wrap around until we have collissions and bouncy stuff done.
    nx = if x > 4000, do: 0, else: x
    ny = if y > 3000, do: 0, else: y
    PositionComponent.move_to(entity_pid, nx, ny, nz)
  end
end
