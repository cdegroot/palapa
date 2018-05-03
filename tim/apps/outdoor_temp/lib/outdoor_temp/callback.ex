defmodule OutdoorTemp.Callback do

  @doc """
  After registering with the server, this will be called regularly
  """

  @callback outdoor_temp_event(id :: String.t, temp :: Float.t) :: any

end
