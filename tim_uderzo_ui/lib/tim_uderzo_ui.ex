defmodule TimUderzoUi do
  @moduledoc """
  This modules draws the TIM thermostat display
  """
  use Clixir
  @clixir_header "tim_uderzo_ui"

  def init() do
    base_dir = Application.app_dir(:tim_uderzo_ui, ".")
    priv_dir = Path.absname("priv", base_dir)

    create_font("sans", Path.join(priv_dir, "FreeSans.ttf"))
  end

  def_c create_font(name, file_name) do
    cdecl "char *": [name, file_name]
    cdecl int: retval

    assert(nvgCreateFont(vg, name, file_name) >= 0)
  end

  def render(win_width, win_height, state) do
    IO.puts "render #{inspect state}"
    draw_inside_temp(state.indoor_temp, win_width, win_height)
    draw_outside_temp(state.outdoor_temp, win_width, win_height)
    draw_set_temp(state.set_temp, win_width, win_height)
    draw_date_time(state.date_time, win_width, win_height)
    draw_override_indicator(state.is_override, win_width, win_height)
    draw_burn_indicator(state.burner_on, state.burner_on_high, state.fan_on, win_width, win_height)
    draw_controls(win_width, win_height)
    #TODO: have temps be historical.
  end

  defp left_column(x), do: 0.1 * x
  defp center_column(x), do: 0.4 * x
  defp display_temp(t), do: "#{:erlang.float_to_binary(t, [decimals: 1])}"

  def draw_inside_temp(temp, w, h) do
    left_column = left_column(w)
    draw_small_text("Inside", left_column, 0.1 * h)
    draw_big_text(display_temp(temp), left_column, 0.16 * h)
  end
  def draw_outside_temp(temp, w, h) do
    left_column = left_column(w)
    draw_small_text("Outside", left_column, 0.4 * h)
    draw_big_text(display_temp(temp), left_column, 0.46 * h)
  end
  def draw_set_temp(temp, w, h) do
    center_column = center_column(w)
    draw_small_text("Set", center_column, 0.2 * h)
    draw_huge_text(display_temp(temp), center_column, 0.26 * h)
  end
  def draw_date_time(dt_string, w, h) do
    left_column = left_column(w)
    draw_small_text(dt_string, left_column, 0.8 * h)
  end

  def draw_override_indicator(_override = true, w, h) do
    draw_small_text("override", center_column(w), 0.5 * h)
  end
  def draw_override_indicator(_override = false, w, h) do
    draw_small_text("program", center_column(w), 0.5 * h)
  end

  def draw_burn_indicator(_burn = true, _high = true, _fan, w, h) do
    draw_burn_indicator("furnace high", w, h)
  end
  def draw_burn_indicator(_burn = true, _high = false, _fan, w, h) do
    draw_burn_indicator("furnace low", w, h)
  end
  def draw_burn_indicator(_burn, _high, _fan = true, w, h) do
    draw_burn_indicator("fan on", w, h)
  end
  def draw_burn_indicator(_burn, _high, _fan, _w, _h) do
  end
  def draw_burn_indicator(string, w, h) do
    draw_small_text(string, center_column(w), 0.6 * h)
  end

  def draw_controls(w, h) do
    aspect = h / w
    draw_button_with_arrow(1, w * 0.75, h * 0.1, w * 0.2, h * 0.2 / aspect)
    draw_button_with_arrow(-1, w * 0.75, h * 0.6, w * 0.2, h * 0.2 / aspect)
  end

  def draw_small_text(t, x, y), do: draw_text(t, String.length(t), 40.0, x, y)
  def draw_big_text(t, x, y), do: draw_text(t, String.length(t), 96.0, x, y)
  def draw_huge_text(t, x, y), do: draw_text(t, String.length(t), 128.0, x, y)

  def_c draw_text(t, tl, sz, x, y) do
    cdecl "char *": t
    cdecl long: tl
    cdecl double: [sz, x, y]

    nvgFontSize(vg, sz)
    nvgFontFace(vg, "sans")
    nvgTextAlign(vg, NVG_ALIGN_LEFT|NVG_ALIGN_TOP)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 255))
    nvgText(vg, x, y, t, t + tl)
  end

  def_c draw_button_with_arrow(up, x, y, w, h) do
    cdecl long: up
    cdecl double: [x, y, w, h]

    nvgBeginPath(vg)
	  nvgRoundedRect(vg, x, y, w, h, w / 20.0)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 128))
    nvgFill(vg)
	  nvgStrokeColor(vg, nvgRGBA(128, 128, 128, 255))
	  nvgStroke(vg)

    nvgBeginPath(vg)
    if up == 1 do
      nvgMoveTo(vg, x + (w * 0.1), y + (h * 0.9))
      nvgLineTo(vg, x + (w * 0.9), y + (h * 0.9))
      nvgLineTo(vg, x + (w * 0.5), y + (h * 0.1))
      nvgFillColor(vg, nvgRGBA(200, 64, 64, 255))
    else
      nvgMoveTo(vg, x + (w * 0.1), y + (h * 0.1))
      nvgLineTo(vg, x + (w * 0.9), y + (h * 0.1))
      nvgLineTo(vg, x + (w * 0.5), y + (h * 0.9))
      nvgFillColor(vg, nvgRGBA(64, 64, 200, 255))
    end
    nvgFill(vg)
	  nvgStrokeColor(vg, nvgRGBA(128, 128, 128, 255))
	  nvgStroke(vg)

  end
end
