defmodule Boids.CirclingBehaviour do
  @moduledoc """
  Behaviour for boids that slowly circle leftwards
  """

  @turn_speed 0.001 # Radians per second

  def make_move(_neighbours, x, y, _v = {vx, vy}, prev_t,
                t \\ :erlang.monotonic_time(:microsecond)) do
    t_fraction = (t - prev_t) / 1_000_000

    {new_x, new_y} = {x + (vx * t_fraction),
                      y + (vy * t_fraction)}

    direction = :math.atan2(y, x) + (@turn_speed * t_fraction)
    magnitude = :math.sqrt(vx * vx + vy * vy)
    {new_vx, new_vy} = {:math.cos(direction) * magnitude,
                        :math.sin(direction) * magnitude}
    {new_x, new_y, {new_vx, new_vy}, t}
  end
end
