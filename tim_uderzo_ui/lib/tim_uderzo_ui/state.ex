defmodule TimUderzoUi.State do
  @moduledoc """
  The UI state, basically what we want to present.
  """

  defstruct [
    :outdoor_temp,
    :indoor_temp,
    :set_temp,
    :date_time,
    :is_override,
    :burner_on,
    :burner_on_high,
    :fan_on
  ]
end
