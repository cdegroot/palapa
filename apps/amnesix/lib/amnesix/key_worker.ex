defmodule Amnesix.KeyWorker do
  @moduledoc """
  This defines a worker that's responsible for a single unique key.

  Two implementation details:
  - Scheduling work is O(n). Build a better data structure if that botters you
  - We use `os_time`, which means warping and stuff is possible. See the previous point ;-)
  end
  """
  defmodule Behaviour do
    use Simpler.Interface

    @doc """
    Schedule a work item. Returns `:ok` when all went well,
    `{:error, {:reason, textual_reason}}` otherwise. Work consists of
    a unique id, the time it needs to be executed, and an mfa to be called.
    """
    defmethod schedule_work(pid :: pid, work :: {String.t, integer, {atom, atom, any}}) :: :ok

    @doc """
    Load state from the state in the argument. Part of initialization,
    refused post-initialization.
    """
    defmethod load_state(pid :: pid, state :: any) :: :ok

    @doc """
    Sent by whoever does initialization to signal completion
    of initialization.
    """
    defmethod initialization_done(pid :: pid) :: :ok
  end

  defmodule Implementation do
    use GenServer
    require Logger

    @max_int 18446744073709551615

    defmodule State do
      defstruct [:state, :timer, :work_items, :next_work_item, :persister_id, :persister_key]
    end

    # Front-end

    def start_link(persister_id, persister_key) do
      GenServer.start_link(__MODULE__, [persister_id, persister_key])
    end

    def schedule_work(worker, work) do
      GenServer.call(worker, {:schedule_work, work})
    end

    def load_state(worker, state) do
      GenServer.call(worker, {:load_state, state})
    end

    def initialization_done(worker) do
      GenServer.call(worker, :initialization_done)
    end

    # Server implementation

    def init([persister_id, persister_key]) do
      {:ok, %State{state: :initializing,
                  work_items: %{},
                  persister_id: persister_id,
                  persister_key: persister_key}}
    end

    def handle_call(:initialization_done, _from, state) do
      Logger.info("Initialization done, ready for work!")
      new_state = state
      |> calculate_next_work_item
      |> set_timer
      {:reply, :ok, %State{new_state | state: :ready}}
    end

    def handle_call({:load_state, persisted_state}, _from, state) do
      {:reply, :ok, %State{state | work_items: persisted_state}}
    end

    def handle_call(_call, _from, state = %State{state: :initializing}) do
      {:reply, {:error, {:initializing, "The worker cannot accept work when initializing"}}, state}
    end

    def handle_call({:schedule_work, work}, _from, state) do
      Logger.info("Schedule work #{inspect(work)}")
      new_state = state
      |> cancel_timer
      |> add_work_item_to_state(work)
      |> calculate_next_work_item
      |> set_timer
      |> persist
      {:reply, :ok, new_state}
    end

    def handle_call(call, from, state) do
      Logger.error("Unexpected call #{inspect(call)} from #{inspect(from)} while in #{inspect(state)}")
      {:error, {:badcall, "Unexpected handle_call received in KeyWorker"}}
    end

    def handle_info(:tick, state) do
      Logger.info("Handle timer tick")
      new_state = state
      |> cancel_timer
      |> execute_next_work_item
      |> remove_next_work_item
      |> set_timer
      |> persist
      {:noreply, new_state}
    end

    # Private shit

    defp cancel_timer(state = %State{timer: nil}), do: state
    defp cancel_timer(state) do
      :timer.cancel(state.timer)
      %State{state | timer: nil}
    end

    defp add_work_item_to_state(state, _work = {key, at, mfa}) do
      %State{state | work_items: Map.put(state.work_items, key, {at, mfa})}
    end

    defp calculate_next_work_item(state) do
      next_work_item = state.work_items
      |> Enum.reduce({nil, @max_int, nil}, fn({key, {at, mfa}}, {cur_key, cur_at, cur_mfa}) ->
        if at < cur_at do
          {key, at, mfa}
        else
          {cur_key, cur_at, cur_mfa}
        end
      end)
      %State{state | next_work_item: next_work_item}
    end

    defp set_timer(state = %State{next_work_item: nil}), do: state
    defp set_timer(state) do
      {_, scheduled_secs, _} = state.next_work_item
      scheduled_delta = (scheduled_secs - now_secs()) * 1000
      timer = :timer.send_after(scheduled_delta, :tick)
      %State{state | timer: timer}
    end

    defp execute_next_work_item(state) do
      {key, at, mfa = {m, f, a}} = state.next_work_item
      execution_delta = now_secs() - at
      Logger.info("Executing #{key}, #{at}, #{inspect(mfa)} with a delta of #{execution_delta}")
      Kernel.apply(m, f, a) # TODO retries and shit.
      state
    end

    defp remove_next_work_item(state) do
      {key, _at, _mfa} = state.next_work_item
      %State{state |
        next_work_item: nil,
        work_items: Map.delete(state.work_items, key)
        }
    end

    defp persist(state = %State{persister_id: nil}), do: state
    defp persist(state) do
      # All we need to persist is work items, we can rebuild the rest from there
      :ok = Amnesix.Persister.persist(state.persister_id, state.persister_key, state.work_items)
      state
    end

    defp now_secs, do: System.os_time(:second)
  end
end
