defmodule TimUderzoUi.Demo do
  @moduledoc """
  Run the Thermostat UI in Demo mode.
  """
  import Uderzo.GenRenderer
  require Logger

  def start_link() do
    # 10 fps should be sufficient for a thermostat. Unless it's a massively multiplayer
    # online thermostat, of course.
    Uderzo.GenRenderer.start_link(__MODULE__, "Thermostat, IMproved", 800, 600, 10, [])
  end

  def init_renderer([]) do
    TimUderzoUi.Display.init()
    {:ok, timestamp()}
  end

  def render_frame(win_width, win_height, _mx, _my, t_start) do
    t = timestamp() - t_start
    TimUderzoUi.Display.render(win_width, win_height, fake_state(t))
    {:ok, t_start}
  end

  defp timestamp, do: :erlang.system_time(:nanosecond) / 1_000_000_000.0

  # Fake some temperatures by different sine waves, etcetera.
  defp fake_state(t) do
    indoor_temp = 25 * :math.sin(t / 10)
    outdoor_temp = 25 * :math.sin(t / 8)
    set_temp = 21.0
    dt = DateTime.utc_now
    {:ok, dt_string} = Timex.format(dt, "{WDshort} {D} {Mfull} {YYYY} {h24}:{m}:{s}")
    %TimUderzoUi.State{
      outdoor_temp: outdoor_temp,
      indoor_temp: indoor_temp,
      set_temp: set_temp,
      date_time: dt_string,
      is_override: false,
      burner_on: (set_temp - indoor_temp) > 0,
      burner_on_high: (set_temp - indoor_temp) > 5,
      fan_on: (set_temp - indoor_temp) < 0
    }
  end
end
