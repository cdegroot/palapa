defmodule MajordomoVault do
  @moduledoc """
  Secrets access. Note that we soon as we read the secrets into memory,
  we're going to assume that they're public knowledge to all code - there
  is no way to have secrets between various parts of a BEAM VM and this
  is not an attack model we want to deal with.
  """

  @doc """
  Get a secret. Vault does not care about the name but it should be unique; therefore,
  something like a path (`{application, subsystem, secret}`) makes sense. To encourage
  that behaviour, let's call the argument that ;-). The only real requirement to the
  path is that it must be a map key and be serializable, though.

  Returns `{:ok, secret}` or something you don't want.
  """
  def get(path) do
    GenServer.call(MajordomoVault.Server, {:get, path})
  end

  @doc """
  Write a secret. The secret key must be available, because this triggers a
  (synchronous) encryption and write of the whole vault data.

  Will error if the secret cannot be written to disk, because that is normally
  a very major problem
  """
  def put!(path, secret) do
    :ok = GenServer.call(MajordomoVault.Server, {:put, path, secret})
  end
end
