defmodule Amnesix.KeyWorkerTest do
  use ExUnit.Case, async: true
  alias Amnesix.KeyWorker

  @far_away 999999999

  defmodule MockPersister do
    def start_link() do
      {:ok, self()}
    end
    def persist(pid, key, data) do
      send(pid, {:persist, key, data})
      :ok
    end
  end

  test "when initializing, commands aren't accepted" do
    {:ok, worker} = KeyWorker.start_link({nil, nil}, nil)
    {:error, {:initializing, _}} = KeyWorker.schedule_work(worker, work_item_in(@far_away))
  end

  test "as soon as initialization is flagged complete, work is accepted" do
    {:ok, worker} = KeyWorker.start_link({nil, nil}, nil)
    KeyWorker.initialization_done(worker)
    :ok = KeyWorker.schedule_work(worker, work_item_in(@far_away))
  end

  test "work is accepted and executed in reasonable time" do
    {worker, _} = initialized_worker()
    :ok = KeyWorker.schedule_work(worker, work_item_in(1))
    assert_receive :done_work, 2_000 # and there we go again...
  end

  test "persistence callback is called whenever work is scheduled" do
    {:ok, worker} = KeyWorker.start_link({MockPersister, self()}, __MODULE__)
    KeyWorker.initialization_done(worker)
    {id, time, mfa} = work_item = work_item_in(@far_away)
    :ok = KeyWorker.schedule_work(worker, work_item)
    # assert_received does a match. Pin our vars with the carets
    assert_received {:persist, __MODULE__, %{^id => {^time, ^mfa}}}
  end

  # Test helper stuff

  def work_item_in(secs_in_future) do
    {"my-unique-id",
     System.os_time(:second) + secs_in_future,
     {Kernel, :send, [self(), :done_work]}}
  end

  def initialized_worker do
    {:ok, pid} = MockPersister.start_link()
    persister = {MockPersister, pid}
    {:ok, worker} = KeyWorker.start_link(persister, __MODULE__)
    KeyWorker.initialization_done(worker)
    {worker, persister}
  end
end

defmodule Amnesix.KeyWorkerTestTwo do
  # Parallelize slow tests by splitting them into different modules

  use ExUnit.Case, async: true
  alias Amnesix.KeyWorker
  import Amnesix.KeyWorkerTest

  test "it will reload state and run jobs from reloaded state" do
    {:ok, worker} = KeyWorker.start_link({nil, nil}, nil)
    {key, at, mfa} = work_item_in(1)
    persisted_state = Map.new
    |> Map.put(key, {at, mfa})
    KeyWorker.load_state(worker, persisted_state)
    KeyWorker.initialization_done(worker)
    assert_receive :done_work, 2_000
  end

end
