defmodule Amnesix.RoutingSupervisor do
  @moduledoc """
  A Supervisor that also maintains a registry of key/process
  pairs to route calls to.
  """
  require Logger

  defmodule State, do: defstruct [:supervisor_pid, :registry, :behaviour]

  @doc """
  Setup the routing supervisor with the indicated `spec` as a worker or
  supervisor spec to use. If `behaviour_module` not is nil, then it's
  interpreted as an interface style module and return values
  will not be naked pids but `{behaviour_module, pid}` tuples. This can
  be used for unit testing, making behaviour pluggable, etcetera.
  """
  def setup(spec, behaviour_module \\ nil) do
    {:ok, pid} = Supervisor.start_link([spec], strategy: :simple_one_for_one)
    %State{supervisor_pid: pid, registry: %{}, behaviour: behaviour_module}
  end

  @doc """
  Returns the pid of the worker for the `key` creating a new one if necessary.
  The return value is a tuple `{:ok, pid, new_state}` where the new state should
  be kept for the next call.
  """
  def pid_of(state, key) do
    new_registry = Map.put_new_lazy(state.registry, key, fn ->
      {:ok, pid} = Supervisor.start_child(state.supervisor_pid, [key])
      Logger.info("Started new child for key #{inspect key} -> #{inspect pid}")
      make_pid(pid, state)
    end)
    {:ok, Map.get(new_registry, key), %State{state | registry: new_registry}}
  end

  @doc """
  Calls the function for every child.
  """
  def do_all(state, callback_fn) do
    state.registry
    |> Map.values
    |> Enum.each(callback_fn)
    :ok
  end

  @doc """
  Shuts down all children. Returns `{:ok, new_state}`.
  """
  def shutdown(state) do
    for {id, _child, _type, _modules} <- Supervisor.which_children(state.supervisor_pid) do
      Supervisor.terminate_child(state.supervisor_pid, id)
      Supervisor.delete_child(state.supervisor_pid, id)
    end
    {:ok, %State{state | registry: %{}}}
  end

  # "Enrich" a pid to work with Simpler.Interface etcetera if we have a behaviour
  defp make_pid(pid, state) do
    if state.behaviour != nil do
      {state.behaviour, pid}
    else
      pid
    end
  end
end
