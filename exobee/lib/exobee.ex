defmodule Exobee do
  @moduledoc """
  Exobee public API routines
  """

  @doc """
  Initialize secrets. This is something that a human being should trigger on the console.
  Secrets are written using MajordomoVault (currently a hardcoded dependency for purposes
  of simplicity)
  """
  def init_secrets() do
    Exobee.TokenManagement.run_pin_protocol()
  end
end
