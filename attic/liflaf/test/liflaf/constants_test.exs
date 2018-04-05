defmodule LifLaf.ConstantsTest do
  use ExUnit.Case, async: true

  use LifLaf.Constants

  # We only run this on my dev macbook - it's suffient for now
  # and saves me from writing the exact same stuff twice or doing
  # other strange crap.
  if :inet.gethostname() == 'oldmac' do
    test "Base directories are correct" do
      assert @config_dir     == "/Users/cees/.liflaf"
      assert @id_file_name   == "/Users/cees/.liflaf/id"
      assert @peer_file_name == "/Users/cees/.liflaf/peers"
      assert @base_dir       == "/Users/cees/LifLaf"
      assert @hash_file_name == ".dir_hash"
    end
  end
end
