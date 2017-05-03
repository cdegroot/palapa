defmodule LifLaf.FileSystemTest do
  use ExUnit.Case, async: true
  use LifLaf.Constants
  use Simpler.Mock

  alias LifLaf.FileSystem

  test "Merkle tree is calculated - on an empty directory" do
    # We emulate
    # a_file
    # a_dir/
    #   another_file
    # As a minimum use case. Fresh directory so no existing .dir_hash files
    {:ok, fs_mock = {fs_mod, _fs_pid}} = Mock.with_expectations do
      # Expect scanning...
      expect_call ls(@base_dir), reply: {:ok, ["a_file", "a_dir"]}
      expect_call stat("#{@base_dir}/a_dir", [time: :posix]),
        reply: %File.Stat{type: :directory}
      expect_call stat("#{@base_dir}/a_file", [time: :posix]),
        reply: %File.Stat{type: :regular}
      expect_call ls("#{@base_dir}/a_dir"), reply: {:ok, ["another_file"]}
      expect_call stat("#{@base_dir}/a_dir/another_file", [time: :posix]),
        reply: %File.Stat{type: :regular}
      # Reading the files for content hashes...
      expect_call read("#{@base_dir}/a_dir/another_file"), reply: "my bytes"
      expect_call read("#{@base_dir}/a_file"), reply: "more bytes"
      # Expect writing new hash files
      expect_call write!("#{@base_dir}/a_dir/.dir_hash", _stuff, [:binary]), reply: :ok
      expect_call write!("#{@base_dir}/.dir_hash", _stuff, [:binary]), reply: :ok
    end

    FileSystem.open(fs_mod)

    Mock.verify(fs_mock)
  end
end
