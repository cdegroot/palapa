defmodule ECS.Systems.SimplePhysicsSystem do
  @moduledoc """
  A very simplistic (for now) physics system that
  uses the position and velocity components to move
  stuff around. I'm not even sure you can call this
  a physics system ;-)
  """
  use GenServer
  alias ECS.{Registry, Entity, Component}
  alias ECS.Components.VelocityComponent

  @fps 25
  @tick_time div(1000, @fps)

  defmodule State do
    @moduledoc false
    defstruct [:registry, :timer]
  end

  def new(registry) do
    GenServer.start_link(__MODULE__, registry)
  end

  @doc """
  Speed at which the physics system runs, in fps
  """
  def fps, do: @fps

  # Server implementation

  def init(registry) do
    timer = :timer.send_interval(@tick_time, self(), :tick)
    {:ok, %State{registry: registry, timer: timer}}
  end

  def handle_info(:tick, state) do
    do_velocity_updates(state)
    do_collissions(state)
    {:noreply, state}
  end

  def do_velocity_updates(state) do
    state.registry
      |> Registry.get_all_for_component(:velocity)
      |> Enum.map(&(VelocityComponent.tick(&1)))
  end

  @doc """
  Calculate all collissions and send entities word about it.
  """
  def do_collissions(state) do
    [collidables, colliders] = state.registry
      |> Registry.get_all_for_components([:collidable, :collider])
    collission_pairs = calculate_collissions(collidables, colliders)
    collission_pairs
    |> Enum.map(fn({subject, object}) ->
      Task.start(fn -> do_collission(subject, object) end)
    end)
  end

  @doc """
  Handle a collission between two entities. The subject is the thing that is certainly
  moving (a collider), the object can be stationary or not. The subject's module gets
  to make the call what to do with this in the form of a function call:

  collission(subject_collider,
             {subject, subject_position, subject_velocity},
             {object, object_collider, object_collidable, object_position, object_velocity})

  with pattern matching (either `object_collider` or `object_collidable` is nil) you can then
  sort out between handling collissions with active or passive objects. Also, the actual
  module of the collider/collidables may of course help here.
  """
  def do_collission(subject, object) do
    # Note that we play stupid here - we're fetching data we had before, but
    # as we're going parallel per task it's not too bad and the code is cleaner.
    IO.puts("#{inspect subject} and #{inspect object} say boom!")

    # The source must be collider: position, collider, velocity
    [subject_collider, subject_position, subject_velocity] =
      Entity.get_components(subject, [:collider, :position, :velocity])

    # The target may either be collider or collidable. A collidable doesn't have/need
    # a velocity. We get them all at once and let the collission handling function figure
    # it out.
    [object_collider, object_collidable, object_position, object_velocity] =
      Entity.get_components(object, [:collider, :collidable, :position, :velocity])

    Component.apply(subject_collider, :collission,
      [{subject, subject_position, subject_velocity},
       {object, object_collider, object_collidable, object_position, object_velocity}])
  end

  @doc """
  Collission detection core functionality. Given a list of
  entities that can collide, figure out one which ones actually
  collide. Both collidables and colliders are entity pids which
  usually came from a registry query for objects with these components.
  """
  def calculate_collissions(collidables, colliders) do
    collidable_objects = get_pos_and_bb(collidables)
    collider_objects = get_pos_and_bb(colliders)
    collider_collidables = for s <- collider_objects, t <- collidable_objects, do: {s, t}
    collider_colliders = for s <- collider_objects, t <- collider_objects do
      if s > t do
        {t, s}
      else
        {s, t}
      end
    end
    (collider_collidables ++ Enum.uniq(collider_colliders))
      |> Enum.filter(fn({s, t}) -> collides?(s, t) end)
      |> Enum.map(fn({s, t}) -> collission_pair(s, t) end)
  end

  defp collides?({same_pid, _, _}, {same_pid, _, _}), do: false
  defp collides?({_s_id, s_pos, s_bb}, {_t_id, t_pos, t_bb}) do
    # Match 2D and 3D; if any z coordinate is nil, it's 2D
    match_2 = s_pos.x < t_pos.x + t_bb.w &&
              s_pos.x + s_bb.w > t_pos.x &&
              s_pos.y < t_pos.y + t_bb.h &&
              s_pos.y + s_bb.h > t_pos.y
    if s_pos.z == nil do
      match_2
    else
      match_2 && s_pos.z < t_pos.z + t_bb.d &&
                 s_pos.z + s_bb.d > t_pos.z
    end
  end

  defp collission_pair({s_id, _, _}, {t_id, _, _}), do: {s_id, t_id}

  defp get_pos_and_bb(entity_pids) do
    entity_pids
    |> Enum.map(fn(entity_pid) ->
      [pos, c1, c2] = Entity.get_components(entity_pid,
                                            [:position, :collider, :collidable])
      bb_component = if c1 == nil, do: c2, else: c1
      {entity_pid, pos, bb_component}
    end)
  end
end
