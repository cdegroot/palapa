defmodule Erix.TimerTest do
  use ExUnit.Case, async: true
  use Simpler.Mock

  test "A process gets roughly the correct amount of ticks" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)
    updater = fn -> Agent.update(agent, fn(x) -> x + 1 end) end
    {:ok, process} = Erix.Timer.start_link(25, updater)

    Process.sleep(250)

    ticks_seen = Agent.get(agent, fn(x) -> x end)
    # expected is 10, plus or minus 25%.
    assert ticks_seen >= 7
    assert ticks_seen <= 13
  end
end
