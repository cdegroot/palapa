defmodule Exobee.Secrets do
  @moduledoc """
  Secrets management. Wrapper around the MajordomoVault
  functionality.
  """

  def application_key() do
    vault_read(:application_key,
      "Please configure the Exobee application key first")
  end

  def refresh_token() do
    vault_read(:refresh_token)
  end

  def access_token() do
    vault_read(:access_token)
  end

  def update_refresh_token(refresh_token) do
    MajordomoVault.put!({Exobee, :refresh_token}, refresh_token)
  end

  def update_access_token(access_token) do
    MajordomoVault.put!({Exobee, :access_token}, access_token)
  end

  defp vault_read(element,
    error \\ "Cannot read a secret; did you log in?") do

    value = MajordomoVault.get({Exobee, element})
    if value == nil do
      {:error, error}
    else
      {:ok, value}
    end
  end

end
