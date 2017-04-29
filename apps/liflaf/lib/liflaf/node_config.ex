defmodule LifLaf.NodeConfig do
  use LifLaf.Constants

  def ensure_config_dir(file_mod) do
    if not file_mod.exists?(@config_dir) do
      file_mod.mkdir!(@config_dir)
    end
  end

  def read_id(file_mod) do
    if file_mod.exists?(@id_file_name) do
      file_mod.read!(@id_file_name)
    else
      new_id = UUID.uuid4()
      file_mod.write!(@id_file_name, new_id, [:binary])
      new_id
    end
  end

  def read_peers(file_mod) do
    case file_mod.read(@peer_file_name) do
      {:ok, data} -> :erlang.binary_to_term(data)
      {:error, _reason} -> []
    end
  end

  def read_config(file_mod \\ File) do
    ensure_config_dir(file_mod)
    id = read_id(file_mod)
    peers = read_peers(file_mod)
    %{id: id, peers: peers}
  end

end