defmodule Amnesix.KeyWorkerTest do
  use ExUnit.Case, async: true
  alias Amnesix.KeyWorker

  @far_away 999999999

  defmodule MockPersister do
    @behaviour Amnesix.Persister
    def start_link(_args) do
      {:ok, self()}
    end
    def persist(pid, key, data) do
      send(pid, {:persist, key, data})
      :ok
    end
  end

  test "when initializing, commands aren't accepted" do
    {:ok, worker} = KeyWorker.Implementation.start_link(nil, nil)
    {:error, {:initializing, _}} = KeyWorker.Implementation.schedule_work(worker, work_item_in(@far_away))
  end

  test "as soon as initialization is flagged complete, work is accepted" do
    {:ok, worker} = KeyWorker.Implementation.start_link(nil, nil)
    KeyWorker.Implementation.initialization_done(worker)
    :ok = KeyWorker.Implementation.schedule_work(worker, work_item_in(@far_away))
  end

  test "work is accepted and executed in reasonable time" do
    {worker, _} = initialized_worker()
    :ok = KeyWorker.Implementation.schedule_work(worker, work_item_in(1))
    assert_receive :done_work, 2_000 # and there we go again...
  end

  test "persistence callback is called whenever work is scheduled" do
    {:ok, worker} = KeyWorker.Implementation.start_link({MockPersister, self()}, __MODULE__)
    KeyWorker.Implementation.initialization_done(worker)
    {id, time, mfa} = work_item = work_item_in(@far_away)
    :ok = KeyWorker.Implementation.schedule_work(worker, work_item)
    # assert_received does a match. Pin our vars with the carets
    assert_received {:persist, __MODULE__, %{^id => {^time, ^mfa}}}
  end

  test "it will reload state and run jobs from reloaded state" do
    {:ok, worker} = KeyWorker.Implementation.start_link(nil, nil)
    {key, at, mfa} = work_item_in(1)
    persisted_state = Map.new
    |> Map.put(key, {at, mfa})
    KeyWorker.Implementation.load_state(worker, persisted_state)
    KeyWorker.Implementation.initialization_done(worker)
    assert_receive :done_work, 2_000
  end

  # Test helper stuff

  def work_item_in(secs_in_future) do
    {"my-unique-id",
     System.os_time(:second) + secs_in_future,
     {Kernel, :send, [self(), :done_work]}}
  end

  defp initialized_worker do
    {:ok, persister} = Amnesix.Persister.start_link(MockPersister)
    {:ok, worker} = KeyWorker.Implementation.start_link(persister, __MODULE__)
    KeyWorker.Implementation.initialization_done(worker)
    {worker, persister}
  end
end
