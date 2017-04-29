defmodule LifLaf.NodeConfigTest do
  use ExUnit.Case, async: true
  use Simpler.Mock
  use LifLaf.Constants

  alias LifLaf.NodeConfig

  test "A node creates the configuration directory if it doesn't exist" do
    {:ok, fs_mock = {fs_mod, _fs_pid}} = Mock.with_expectations do
      expect_call exists?(@config_dir), reply: false
      expect_call mkdir!(@config_dir)
    end

    NodeConfig.ensure_config_dir(fs_mod)

    Mock.verify(fs_mock)
  end

  test "A node create a node id if it doesn't exist" do
    {:ok, fs_mock = {fs_mod, _fs_pid}} = Mock.with_expectations do
      expect_call exists?(@id_file_name), reply: false
      expect_call write!(@id_file_name, _contents, [:binary])
    end

    _ = NodeConfig.read_id(fs_mod)

    Mock.verify(fs_mock)
  end

  test "A node reads the existing node id if it exists" do
    some_id = "well, this is me"
    {:ok, fs_mock = {fs_mod, _fs_pid}} = Mock.with_expectations do
      expect_call exists?(@id_file_name), reply: true
      expect_call read!(@id_file_name), reply: some_id
    end

    id = NodeConfig.read_id(fs_mod)

    assert id == some_id
    Mock.verify(fs_mock)
  end

  test "A node reads the peers config file" do
    peers = [{"foosie", "node@host.demo.com"}, {"barto", "ieek@otherhost.demo.com"}]
    peers_data = :erlang.term_to_binary(peers)
    {:ok, fs_mock = {fs_mod, _fs_pid}} = Mock.with_expectations do
      expect_call read(@peer_file_name), reply: {:ok, peers_data}
    end

    read_peers = NodeConfig.read_peers(fs_mod)

    assert read_peers == peers
    Mock.verify(fs_mock)
  end

  test "If no peers config file is found, empty list is returned" do
    {:ok, fs_mock = {fs_mod, _fs_pid}} = Mock.with_expectations do
      expect_call read(@peer_file_name), reply: {:error, :enoent}
    end

    read_peers = NodeConfig.read_peers(fs_mod)

    assert read_peers == []
    Mock.verify(fs_mock)
  end

  test "Putting it all together" do
    peers = [{"foosie", "node@host.demo.com"}, {"barto", "ieek@otherhost.demo.com"}]
    peers_data = :erlang.term_to_binary(peers)
    some_id = "well, this is me"
    {:ok, fs_mock = {fs_mod, _fs_pid}} = Mock.with_expectations do
      expect_call exists?(@config_dir), reply: true
      expect_call exists?(@id_file_name), reply: true
      expect_call read!(@id_file_name), reply: some_id
      expect_call read(@peer_file_name), reply: {:ok, peers_data}
    end

    read_config = NodeConfig.read_config(fs_mod)

    assert read_config == %{peers: peers, id: some_id}
    Mock.verify(fs_mock)
  end
end
