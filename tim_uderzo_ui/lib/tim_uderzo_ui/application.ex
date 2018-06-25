defmodule TimUderzoUi.Application do
  use Application

  def start(_, _) do
    {:ok, _pid} = TimUderzoUi.Demo.start_link()
    Process.sleep(:infinity)
  end
end
