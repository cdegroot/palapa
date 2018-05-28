defmodule Pong do
  @moduledoc """
  Pong main module. This will start a registry, the physics and UI
  loops, and build objects. Everything else is taking care of in the
  various loops.

      Pong.start

  is the entry point, or run Pong as an application.
  """
  use Application

  def start(_, _) do
    {:ok, registry} = ECS.Registry.new(:pong)
    build_objects(registry)
  end

  defp build_objects(registry) do
    # TODO supervision hierarchy?
    Pong.Ball.new(registry)
    Pong.Wall.upper(registry)
    Pong.Wall.lower(registry)
    left = Pong.Paddle.left(registry)
    Pong.Paddle.right(registry)
    ECS.Systems.SimplePhysicsSystem.new(registry)
    Pong.UI.start_link(registry, %{
      :wx_const.c_WXK_DOWN => {Pong.Paddle, :down, [left]},
      :wx_const.c_WXK_UP   => {Pong.Paddle, :up, [left]}
    })
  end

  def start do
    start(nil, nil)
  end
end
