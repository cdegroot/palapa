defmodule LifLaf.NodeTest do
  use ExUnit.Case, async: true
  use LifLaf.Constants
  use Simpler.Mock

  alias LifLaf.Node

  test "A node globally registers itself under its id" do
    uuid = UUID.uuid4
    name = String.to_atom(uuid)
    config = %{id: uuid, peers: []}
    {:ok, config_mock = {config_mod, _config_pid}} = Mock.with_expectations do
      expect_call read_config(), reply: config
    end

    {:ok, pid} = Node.start_link(config_mod)

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

    {:ok, pid} = Node.start_link(config_mod, node_mod)

    Mock.verify(config_mock)
    Mock.verify(node_mock)
  end
end
