defmodule Control.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([Control.State], strategy: :one_for_all)
  end
end
