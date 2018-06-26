defmodule TimUderzoUi.Application do
  use Application

  def start(_, _) do
    IO.puts("Starting up TIM UI. Sleeping a bit to stabilize drivers on nerves system.")
    Process.sleep(10_000)
    IO.puts("Running UI.")
    {:ok, _pid} = TimUderzoUi.Demo.start_link()
    Process.sleep(:infinity)
  end
end
