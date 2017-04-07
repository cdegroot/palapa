defmodule ECS.Registry do
  @moduledoc """
  A Registry that keeps a tab on what entities have which components. This
  can be used by System instances to operate on all components, etcetera.
  """
  use GenServer

  def new do
    GenServer.start_link(__MODULE__, [])
  end

  def register_component(registry_pid, entity_pid, component_name) do
    GenServer.cast(registry_pid, {:register_component, entity_pid, component_name})
  end

  def unregister_component(registry_pid, entity_pid, component_name) do
    GenServer.cast(registry_pid, {:unregister_component, entity_pid, component_name})
  end

  def get_all_for_component(registry_pid, component_name) do
    GenServer.call(registry_pid, {:get_all_for_component, component_name})
  end

  def get_all_for_components(registry_pid, component_names) do
    GenServer.call(registry_pid, {:get_all_for_components, component_names})
  end

  # Server implementation

  def init([]) do
    {:ok, %{}}
  end

  def handle_cast({:register_component, entity_pid, component_name}, state) do
    {_, new_state} = Map.get_and_update(state, component_name, fn cur ->
      {cur, (if cur, do: [entity_pid | cur], else: [entity_pid])}
    end)
    {:noreply, new_state}
  end

  def handle_cast({:unregister_component, entity_pid, component_name}, state) do
    {_, new_state} = Map.get_and_update(state, component_name, fn cur ->
      {cur, (if cur, do: List.delete(cur, entity_pid), else: [])}
    end)
    {:noreply, new_state}
  end

  def handle_call({:get_all_for_component, component_name}, _from, state) do
    {:reply, Map.get(state, component_name, []), state}
  end

  def handle_call({:get_all_for_components, component_names}, _from, state) do
    result = component_names
    |> Enum.map(fn(component_name) -> Map.get(state, component_name, []) end)
    {:reply, result, state}
  end
end
