defmodule ECS.Entity do
  @moduledoc """
  Entity part of an Entity-Component-System architecture. An Entity
  is represented as an id and a map of components.
  """
  alias ECS.{IdComponent, RegistryComponent, Registry}
  use GenServer

  @doc """
  Instantiate a new entity
  """
  def new do
    new([])
  end
  def new(components, registry \\ nil) do
    components = if registry do
      reg_component = RegistryComponent.new([value: registry])
      [reg_component|components]
    else
      components
    end
    id = IdComponent.new([value: UUID.uuid1()])
    state = [id | components]
      |> Enum.map(fn component -> {component_atom(component), component} end)
      |> Enum.into(%{})
    {:ok, pid} = GenServer.start_link(__MODULE__, state)
    pid
  end

  def get_component(entity_pid, component_name) do
    hd(get_components(entity_pid, [component_name]))
  end

  def get_components(entity_pid, component_names) do
    GenServer.call(entity_pid, {:get_components, component_names})
  end

  def set_component(entity_pid, component) do
    GenServer.cast(entity_pid, {:set_component, component})
  end

  def remove_component(entity_pid, component_name) do
    GenServer.cast(entity_pid, {:remove_component, component_name})
  end

  def id(entity_pid) do
    get_component(entity_pid, :id)
  end

  def update_component(entity_pid, component_name, update_fun) do
    GenServer.cast(entity_pid, {:update_component, component_name, update_fun})
  end

  # Server implementation

  def init(state) do
    maybe_register_components(state)
    {:ok, state}
  end

  def handle_call({:get_components, component_names}, _from, state) do
    components = component_names
      |> Enum.map(&Map.get(state, &1))
    {:reply, components, state}
  end

  def handle_cast({:set_component, component}, state) do
    component_name = component_atom(component)
    if !Map.has_key?(state, component_name) do
      maybe_register_component(state, component_name)
    end
    {:noreply, Map.put(state, component_name, component)}
  end

  def handle_cast({:remove_component, component_name}, state) do
    if Map.has_key?(state, component_name) do
      maybe_unregister_component(state, component_name)
    end
    {:noreply, Map.delete(state, component_name)}
  end

  def handle_cast({:update_component, component_name, update_fun}, state) do
    {_, new_state} = if Map.has_key?(state, component_name) do
      Map.get_and_update(state, component_name, fn cur ->
        {cur, update_fun.(cur)}
      end)
    else
      state
    end
    {:noreply, new_state}
  end

  defp maybe_register_components(state) do
    state
      |> Map.values
      |> Enum.map(&component_atom/1)
      |> Enum.map(&(maybe_register_component(state, &1)))
  end

  defp maybe_register_component(%{registry: registry}, component_name) do
    Registry.register_component(registry.value, self(), component_name)
  end
  defp maybe_register_component(_state, _component_name) do
  end

  defp maybe_unregister_component(%{registry: registry}, component_name) do
    Registry.unregister_component(registry.value, self(), component_name)
  end
  defp maybe_unregister_component(_state, _component_name) do
  end

  # Inspired by https://github.com/joshforisha/ecs
  defp component_atom(component) do
    component.__struct__
    |> Atom.to_string
    |> String.split(".")
    |> List.last
    |> String.replace("Component", "")
    |> Macro.underscore
    |> String.to_atom
  end
end
