defmodule Pong.Ball do
  @moduledoc """
  Stuff that has to do with the ball in a game of pong
  """
  alias ECS.Entity
  alias ECS.Components.{PositionComponent, VelocityComponent}
  use Pong.Constants

  defmodule RenderComponent do
    @moduledoc """
    Component responsible for rendering the pong ball.
    """
    import ECS.Component
    use Pong.Constants

    component_fields []

    def render(_render, position, dc) do
      :wxDC.setBrush(dc, :wxBrush.new({0, 255, 0}))
      :wxDC.drawCircle(dc, {round(position.x) + @ball_radius,
                            round(position.y) + @ball_radius},
                           @ball_radius)
    end
  end

  defmodule ColliderComponent do
    @moduledoc """
    Collission handling for the pong ball.
    """
    import ECS.Component
    alias ECS.Math
    use Pong.Constants

    component_fields [:w, :h]

    # collide with wall
    def collission(_self, {self_id, _self_pos, self_vel},
      {_wall_id, nil, %{tag: :wall}, wall_pos, nil}) do
      wall_norm = if Wall.upper?(wall_pos), do: {0, 1}, else: {0, -1}
      bounce(self_id, self_vel, wall_norm)
    end

    # collide with paddle
    def collission(_self, {self_id, _self_pos, self_vel},
      {_paddle_id, nil, %{tag: :paddle}, paddle_pos, nil}) do
      paddle_norm = if Paddle.left?(paddle_pos), do: {1, 0}, else: {-1, 0}
      bounce(self_id, self_vel, paddle_norm)
    end

    defp bounce(self_id, self_vel, norm) do
      {nvx, nvy} = Math.bounce({self_vel.vx, self_vel.vy}, norm)
      Entity.set_component(self_id, VelocityComponent.new([vx: nvx, vy: nvy]))
    end
  end

  def new(registry) do
    # Start the ball in the middle, traveling roughly
    # to the right. Fixed for now, we can always randomize
    # later.
    Entity.new([
        PositionComponent.new([x: @field_width / 2, y: @field_height / 2]),
        VelocityComponent.from_polar(@ball_speed, 0.5236),
        RenderComponent.new(),
        ColliderComponent.new([w: @ball_radius * 2, h: @ball_radius * 2])],
      registry)
  end
end
