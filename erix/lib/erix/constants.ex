defmodule Erix.Constants do
  defmacro __using__(_opts) do
    quote do
      # How often we tick
      @tick_time_ms 100

      # How long a follower waits for no heartbeats
      @heartbeat_timeout_ticks 5

      # How long a candidate waits for an election result
      @election_timeout_ticks 10
    end
  end
end
