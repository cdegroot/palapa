defmodule OutdoorTemp do
  @moduledoc """
  Starts the application by initializing the supervisor
  and genserver that monitor the rtl_433 process.
  """

  use Application

  def start(_type, _args) do
    children = [%{
      id: OutdoorTemp,
      start: {OutdoorTemp.Server, :start_link, []}
    }]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
