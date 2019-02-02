defmodule MajordomoVault.File do
  @moduledoc """
  Actual encryption/decryption code
  """

  require Logger

  @doc """
  Decrypt and read the file. Returns the Erlang term contents stored in the file,
  normally a map. If the file does not exist, an empty Map is returned.
  """
  def decrypt_and_read do
    if File.exists?(data_path()) do
      do_decrypt_and_read()
    else
      {:ok, %{}}
    end
  end

  @doc """
  Encrypt the binary representation of the term and write it to the file.
  """
  def encrypt_and_write(new_data) do
    {:ok, key} = get_key()
    iv = :crypto.strong_rand_bytes(16)
    new_bytes = :erlang.term_to_binary(new_data)
    state = :crypto.stream_init(:aes_ctr, key, iv)
    {_state, ciphertext} = :crypto.stream_encrypt(state, new_bytes)
    :ok = File.write(data_path(), iv <> ciphertext)
  end

  defp do_decrypt_and_read() do
    {:ok, key} = get_key()
    {:ok, <<iv :: binary - size(16), data :: binary>>} = File.read(data_path())
    state = :crypto.stream_init(:aes_ctr, key, iv)
    {_state, plaintext} = :crypto.stream_decrypt(state, data)
    {:ok, :erlang.binary_to_term(plaintext)}
  end

  defp get_key() do
    if File.exists?(pass_path()) do
      read_key()
    else
      create_key()
    end
  end

  defp read_key() do
    {:ok, _key} = File.read(pass_path())
  end

  defp create_key() do
    key = :crypto.strong_rand_bytes(32)
    :ok = File.write(pass_path(), key)
    :ok = File.chmod(pass_path(), 0o400)
    Logger.info("Majordomo Vault created a new key in #{pass_path()}")
    Logger.info("It is recommended to move this key to a safe place after startup. See the docs.")
    {:ok, key}
  end

  defp data_path() do
    Path.join(System.user_home!(), ".majordomo.vault")
  end

  defp pass_path() do
    Path.join(System.user_home!(), ".majordomo.passphrase")
  end
end
