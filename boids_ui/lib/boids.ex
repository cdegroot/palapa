defmodule Boids do
  @moduledoc """
  Fake boids genserver. We model a bunch of random boids on a [0, 1] by [0, 1] torus.
  """
  use GenServer

  @model_fps 50
  @ms_between_frames div(1_000, @model_fps)

  @speed 0.25 / @model_fps # in frame per second so 0.25 is a quarter frame per second.

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # TODO make it send boids to process? More async?
  def get_boids do
    GenServer.call(__MODULE__, :get_boids)
  end

  def init([]) do
    Process.send_after(self(), :tick, @ms_between_frames)
    {:ok, Enum.map(1..50, fn _ -> {:rand.uniform(), :rand.uniform(), :rand.normal()} end)}
  end

  def handle_call(:get_boids, _from, boids) do
    {:reply, boids, boids}
  end

  def handle_info(:tick, boids) do
    new_boids = update_state(boids)
    Process.send_after(self(), :tick, @ms_between_frames)
    {:noreply, new_boids}
  end

  def update_state(boids) do
    Enum.map(boids, fn {x, y, direction} ->
      update_state(x, y, direction)
    end)
  end
  def update_state(x, y, direction) do
    dx = :math.cos(direction) * @speed
    dy = :math.sin(direction) * @speed
    {new_x, new_y} = {bound(x + dx), bound(y + dy)}
    new_state = {new_x, new_y, direction + 0.001}
    #IO.puts("(#{x}, #{y}, #{direction}) -> (#{dx}, #{dy}) -> #{inspect new_state}")
    new_state
  end

  # This makes everything work like a torus. I can do math!
  def bound(value) do
    cond do
      value < 0.0 -> value + 1.0
      value > 1.0 -> value - 1.0
      value -> value
    end
  end

  P
end
