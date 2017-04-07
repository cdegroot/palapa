defmodule Pong.Constants do
  @moduledoc """
  A bunch of constants that describes the field, etcetera. This is all
  in logical units that need to be mapped on physical units. The origin
  is top left.

  For velocities, we depend on the tick time of ECS' SimplePhysicsSystem
  in terms of frames per second. We normalize everything to 100 fps (so
  a speed of "1" would be 100 per second, etcetera).

  To keep things efficient, the constants are defined inside a __using__
  macro.
  """
  alias ECS.Systems.SimplePhysicsSystem

  defmacro __using__(_opts) do
    physics_fps = SimplePhysicsSystem.fps
    fps_factor = 100 / physics_fps

    # Note that this is the speed, iow the magnitude of
    # the velocity.
    absolute_ball_speed = 10 # or that times 100 per second
    physics_system_relative_ball_speed = round(absolute_ball_speed * fps_factor)

    quote do
      @field_width   4000
      @field_height  3000
      @paddle_width    50
      @ball_radius     50
      @ui_fps          25

      @paddle_height  div(@field_height, 6)
      @paddle_margin  2 * @paddle_width
      @ball_speed     unquote(physics_system_relative_ball_speed)
      @paddle_speed   40 # in terms of units per ui framerate!
    end
  end
end
