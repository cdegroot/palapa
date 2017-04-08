defmodule Pong.Paddle do
  @moduledoc """
  The paddle thingie
  """
  alias ECS.Entity
  alias ECS.Components.{PositionComponent, CollidableComponent}
  use Pong.Constants

  defmodule RenderComponent do
    @moduledoc """
    Component responsible for rendering the paddle
    """
    import ECS.Component
    use Pong.Constants

    component_fields []

    def render(_render, position, dc) do
      :wxDC.setBrush(dc, :wxBrush.new({255, 255, 0}))
      :wxDC.drawRectangle(dc, {position.x, position.y, @paddle_width, @paddle_height})
    end
  end

  @doc "Construct the left paddle"
  def left(registry), do: new(registry, @paddle_margin)
  @doc "Construct the right paddle"
  def right(registry), do: new(registry, @field_width - @paddle_width - @paddle_margin)

  @doc "Returns true if this the position refers to the left paddle"
  def left?(pos), do: pos.x == @paddle_margin

  @doc "Construct a paddle"
  def new(registry, x) do
    Entity.new([
        PositionComponent.new([x: x, y: div(@field_height, 2)]),
        CollidableComponent.new([w: @paddle_width, h: @paddle_height, tag: :paddle]),
        RenderComponent.new()],
      registry)
  end

  @doc "Move the paddle up a notch"
  def up(paddle) do
    move(paddle, -1 * @paddle_speed)
  end
  @doc "Move the paddle down a notch"
  def down(paddle) do
    move(paddle, @paddle_speed)
  end

  defp move(paddle, amount) do
    cur_pos = Entity.get_component(paddle, :position)
    can_do = (amount < 0 && cur_pos.y + amount >= 0) or
             (amount > 0 && cur_pos.y + @paddle_height + amount < @field_height)
    if can_do do
      new_pos = PositionComponent.new([x: cur_pos.x, y: cur_pos.y + amount])
      Entity.set_component(paddle, new_pos)
    end
  end
end
