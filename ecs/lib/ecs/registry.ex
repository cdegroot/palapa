defmodule ECS.Registry do
  @moduledoc """
  A Registry that keeps a tab on what entities have which components. This
  can be used by System instances to operate on all components, etcetera.

  Basically, it's a wrapper around Registry.
  """
  use GenServer
  alias Elixir.Registry, as: ExReg

  def new(name) do
    {:ok, _pid} = ExReg.start_link(:duplicate, name)
    {:ok, name}
  end

  def register_component(registry, component_name) do
    ExReg.register(registry, component_name, :nothing)
  end

  def unregister_component(registry, component_name) do
    ExReg.unregister(registry, component_name)
  end

  def get_all_for_component(registry, component_name) do
    ExReg.lookup(registry, component_name)
    |> Enum.map(fn({pid, _}) -> pid end)
  end

  def get_all_for_components(registry, component_names) do
    component_names
    |> Enum.map(&(get_all_for_component(registry, &1)))
  end
end
