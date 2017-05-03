defmodule LifLaf.FileSystem do
  @moduledoc """
  This module takes care of the filesystem and operations on it. Basically
  everything that has to do with the `~/LifLaf` dir.
  """
  use LifLaf.Constants

  def open(file_mod \\ File) do
    scan_tree(file_mod, @base_dir)
  end

  @doc "Scan the subtree and recurse"
  def scan_tree(file_mod, dir) do
    {:ok, entries} = dir
    |> file_mod.ls
    entries = entries
    |> Enum.sort
    stats = entries
    |> Enum.map(fn(entry) ->
      {entry, file_mod.stat(mkpath(dir, entry), [time: :posix])}
    end)
    grouped = stats
    |> Enum.group_by(fn({_, stat}) -> stat.type
    end)
    dirs = grouped[:directory] || []
    files = grouped[:regular] || []
    dir_hashes = dirs
    |> Enum.map(fn({subdir, _stat}) ->
        {subdir, scan_tree(file_mod, mkpath(dir, subdir))}
    end)
    file_hashes = files
    |> Enum.map(fn({file, stat}) ->
      {file, hash_file(file_mod, mkpath(dir, file), stat)}
    end)
    child_hashes = dir_hashes ++ file_hashes
    dir_hash = hash_dir(dir, child_hashes)
    write_hash_file(file_mod, dir, dir_hash, child_hashes)
    dir_hash
  end

  defp mkpath(dir, entry), do: dir <> "/" <> entry

  # Calculate hash of a single file
  defp hash_file(file_mod, file, stat) do
    # TODO keep this (and thus the binary) in a separate process for simpler GC?
    file
    |> file_mod.read
    |> :xxhash.hash64
  end

  # Calculate hash of a whole directory
  defp hash_dir(dir, child_hashes) do
    hash = :xxhash.hash64_init
    :xxhash.hash64_update(hash, dir)
    :xxhash.hash64_update(hash, :erlang.term_to_binary(child_hashes))
    :xxhash.hash64_digest(hash)
  end

  # Write hashes out.
  defp write_hash_file(file_mod, dir, dir_hash, child_hashes) do
    info = {dir_hash, child_hashes} |> :erlang.term_to_binary
    file_mod.write!(mkpath(dir, @hash_file_name), info, [:binary])
  end
end
