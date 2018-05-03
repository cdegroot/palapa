defmodule Amnesix.RoutingSupervisorTest do
  use ExUnit.Case, async: true
  require Logger

  alias Amnesix.RoutingSupervisor

  defmodule TestWorker do
    use GenServer
    def start_link(config_data, routing_key) do
      GenServer.start_link(__MODULE__, {config_data, routing_key})
    end
  end

  test "Routing supervisor creates a new process with the factory function" do
    spec = Supervisor.Spec.worker(TestWorker, [42], restart: :transient)

    router_state = RoutingSupervisor.setup(spec)

    {:ok, pid, router_state} = RoutingSupervisor.pid_of(router_state, "my key")
    assert is_pid(pid)

    {:ok, pid_again, router_state} = RoutingSupervisor.pid_of(router_state, "my key")
    assert pid == pid_again

    {:ok, another_pid, _router_state} = RoutingSupervisor.pid_of(router_state, "another key")
    assert pid != another_pid

    # Test that the state is ok.
    assert :sys.get_state(pid) == {42, "my key"}
    assert :sys.get_state(another_pid) == {42, "another key"}
  end

  test "On do_all all children get the call" do
    spec = Supervisor.Spec.worker(TestWorker, [42], restart: :transient)

    router_state = RoutingSupervisor.setup(spec)

    {:ok, pid_one, router_state} = RoutingSupervisor.pid_of(router_state, "my key")
    {:ok, pid_two, router_state} = RoutingSupervisor.pid_of(router_state, "another key")

    test_pid = self()
    :ok = RoutingSupervisor.do_all(router_state, fn(pid) ->
      send(test_pid, {:do_all, pid})
    end)

    assert_received {:do_all, ^pid_one}
    assert_received {:do_all, ^pid_two}
  end
end
