defmodule SimpleMockTest do
  @moduledoc """
  Mocking without having to specify module interfaces first.
  """

  use ExUnit.Case, async: true
  require Logger
  use Simpler.Mock

  defmodule ModuleUnderTest do
    use GenServer

    def start_link(dependency_ref = {_mod, _pid}) do
      GenServer.start_link(__MODULE__, dependency_ref)
    end

    def do_something_with_dependency(pid) do
      GenServer.call(pid, :do_something_with_dependency)
    end
    def do_something_often_with_dependency(pid, times) do
      GenServer.call(pid, {:do_something_often_with_dependency, times})
    end

    def init(dependency_ref) do
      {:ok, dependency_ref}
    end
    def handle_call(:do_something_with_dependency, _from,
      dependency_ref = {dependency_mod, dependency_pid}) do

      result = dependency_mod.some_call(dependency_pid, "you", "me")
      {:reply, result, dependency_ref}
    end

    def handle_call({:do_something_often_with_dependency, times}, _from,
      dependency_ref = {dependency_mod, dependency_pid}) do

      result = for _ <- 1..times do
        dependency_mod.some_call(dependency_pid, "you", "me")
      end
      {:reply, result, dependency_ref}
    end
  end

  test "mock definition works" do
    # Setup mocks and module under test
    you = "you" # Note that this should not trigger an "unused" warning.
    {:ok, mock_dependency = {_mod, _pid}} = Mock.with_expectations do
      expect_call some_call(_some_pid, you, "me"), reply: :ok_by_me
    end

    {:ok, mut} = ModuleUnderTest.start_link(mock_dependency)

    # Test execution
    assert :ok_by_me == ModuleUnderTest.do_something_with_dependency(mut)

    # Verification
    Mock.verify(mock_dependency)
  end

  test "n times works" do
    {:ok, mock_dependency = {_mod, _pid}} = Mock.with_expectations do
      expect_call some_call(_some_pid, "you", "me"), reply: :ok_by_me, times: 5
    end

    {:ok, mut} = ModuleUnderTest.start_link(mock_dependency)

    answer = for _ <- 1..5, do: :ok_by_me
    # Test execution
    assert answer == ModuleUnderTest.do_something_often_with_dependency(mut, 5)

    # Verification
    Mock.verify(mock_dependency)
  end

  test "Any times works" do
    {:ok, mock_dependency = {_mod, _pid}} = Mock.with_expectations do
      expect_call some_call(_some_pid, "you", "me"), reply: :ok_by_me, times: :any
    end

    {:ok, mut} = ModuleUnderTest.start_link(mock_dependency)

    answer = for _ <- 1..25, do: :ok_by_me
    # Test execution
    assert answer == ModuleUnderTest.do_something_often_with_dependency(mut, 25)

    # Verification
    Mock.verify(mock_dependency)
  end
end
