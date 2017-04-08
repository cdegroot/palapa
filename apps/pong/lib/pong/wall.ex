defmodule Pong.Wall do
  @moduledoc """
  The lower and uppper walls of pong
  """
  alias ECS.Entity
  alias ECS.Components.{PositionComponent, CollidableComponent}
  use Pong.Constants

  defmodule RenderComponent do
    @moduledoc """
    Component responsible for rendering the wall.
    """
    import ECS.Component
    use Pong.Constants

    component_fields []

    def height, do: div(@field_height, 40)

    def render(_render, position, dc) do
      blue = if position.y == 0, do: 128, else: 255
      :wxDC.setBrush(dc, :wxBrush.new({255, 255, blue}))
      :wxDC.drawRectangle(dc, {position.x, position.y, @field_width, height()})
    end
  end

  def upper(registry), do: new(registry, 0)
  def lower(registry), do: new(registry, @field_height - RenderComponent.height())

  @doc "Returns true if the position refers to the upper wall"
  def upper?(pos), do: pos.y == 0

  def new(registry, y) do
    Entity.new([
        PositionComponent.new([x: 0, y: y]),
        CollidableComponent.new([w: @field_width, h: RenderComponent.height(), tag: :wall]),
        RenderComponent.new()],
      registry)
  end
end
