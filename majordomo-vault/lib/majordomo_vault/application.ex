defmodule MajordomoVault.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([MajordomoVault.Server], strategy: :one_for_one)
  end
end
