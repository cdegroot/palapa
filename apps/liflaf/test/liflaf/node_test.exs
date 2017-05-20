defmodule LifLaf.NodeTest do
  use ExUnit.Case, async: true
  use LifLaf.Constants
  use Simpler.Mock

  alias LifLaf.Node

  def dummy_fs do
    {:ok, {mod, _pid}} = Mock.with_expectations do
      expect_call open(), reply: 42
    end
    mod
  end
  def dummy_node do
    {:ok, {mod, _pid}} = Mock.with_expectations do
    end
    mod
  end

  test "A node globally registers itself under its id" do
    uuid = Simpler.UniqueId.unique_id_string()
    name = String.to_atom(uuid)
    config = %{id: uuid, peers: []}
    {:ok, config_mock = {config_mod, _config_pid}} = Mock.with_expectations do
      expect_call read_config(), reply: config
    end

    {:ok, pid} = Node.start_link(config_mod, dummy_node(), dummy_fs())

    assert :global.whereis_name(name) == pid
    Mock.verify(config_mock)
  end

  test "A node will connect with its peers" do
    config = %{id: "me!", peers: [{"peer1", "foo@bar.com"}, {"peer2", "baz@quux.com"}]}
    {:ok, config_mock = {config_mod, _config_pid}} = Mock.with_expectations do
      expect_call read_config(), reply: config
    end
    {:ok, node_mock = {node_mod, _node_pid}} = Mock.with_expectations do
      expect_call connect("foo@bar.com")
      expect_call connect("baz@quux.com")
    end

    {:ok, _pid} = Node.start_link(config_mod, node_mod, dummy_fs())

    Mock.verify(config_mock)
    Mock.verify(node_mock)
  end

  test "Every second, a node sends the hash of its root directory to its peers" do
    # Every second is done by a ticker so we test what happens when a :tick is received

    # Start a host with self() as a mock, assert we get the message back.
  end
end
