defmodule LifLaf.Constants do
  @moduledoc """
  A module with constants that can be used by whatever modules need it.
  """

  defmacro __using__(_opts) do
    home_dir = System.get_env("HOME")
    quote do
      @config_dir     "#{unquote(home_dir)}/.liflaf"
      @id_file_name   "#{@config_dir}/id"
      @peer_file_name "#{@config_dir}/peers"
      @base_dir       "#{unquote(home_dir)}/LifLaf"
      @hash_file_name ".dir_hash"
    end
  end
end
