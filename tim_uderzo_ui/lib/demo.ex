defmodule Demo do
  @moduledoc """
  Run the Thermostat UI in Demo mode.
  """
  import Uderzo.Bindings
  require Logger

  def run do
    t_start = timestamp()
    uderzo_init(self())
    receive do
      _msg ->
        glfw_create_window(800, 600, "Uderzo/NanoVG Demo", self())
        receive do
          {:glfw_create_window_result, window} ->
            TimUderzoUi.init()
            render_loop(window, t_start)
            glfw_destroy_window(window)
          msg ->
            IO.puts("Received unknown message #{inspect msg}")
        end
    end
  end

  defp render_loop(window, t_start) do
    uderzo_start_frame(window, self())
    receive do
      {:uderzo_start_frame_result, _mx, _my, win_width, win_height} ->
        t = timestamp() - t_start
        TimUderzoUi.render(win_width, win_height, fake_state(t))
        uderzo_end_frame(window, self())
        receive do
          :uderzo_end_frame_done ->
            Process.sleep(1000) # TODO precise fps timing.
            # And recurse...
            render_loop(window, t_start)
        end
    end
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
