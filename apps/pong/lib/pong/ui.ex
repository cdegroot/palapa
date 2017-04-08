defmodule Pong.UI do
  @moduledoc """
  Pong's WX UI.

  A lot of this is thanks to
  https://wtfleming.github.io/2016/01/06/getting-started-opengl-elixir/
  """
  use Bitwise
  use Pong.Constants
  alias ECS.{Registry, Entity, Component}
  @behaviour :wx_object

  @size %{w: 640, h: 480}

  @refresh_interval div(1000, @ui_fps)

  defmodule State do
    @moduledoc "State for Pong UI"
    defstruct [:wx, :frame, :timer, :registry, :buffer, :scale, :keymap]
  end

  # API

  def start_link(registry, keymap) do
    :wx_object.start_link(__MODULE__, {registry, keymap}, [])
  end

  # Server implementation

  def init({registry, keymap}) do
    wx = :wx.new()

    frame = :wxFrame.new(wx, :wx_const.c_wxID_ANY, "Pong", [{:size, {@size.w, @size.h}}])
    :wxWindow.connect(frame, :close_window)
    :wxWindow.connect(frame, :paint, [:callback])
    :wxWindow.connect(frame, :size)
    :wxWindow.setBackgroundStyle(frame, :wx_const.c_wxBG_STYLE_CUSTOM)
    :wxFrame.show(frame)

    # Periodically send a message to trigger a redraw of the scene
    timer = :timer.send_interval(@refresh_interval, self(), :update)

    state = %State{wx: wx, frame: frame, timer: timer, registry: registry, keymap: keymap}
    resized_state = resize(@size.w, @size.h, state)

    {frame, resized_state}
  end

  # Tempting to have a run-time-updatable game ;-)
  def code_change(_, _, _) do
    {:error, :not_implemented}
  end

  def handle_info(:stop, state) do
    :timer.cancel(state.timer)
    {:stop, :normal, state}
  end

  def handle_info(:update, state) do
    force_repaint(state)
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def handle_event({:wx, _, _, _, {:wxSize, :size, {width, height}, _}}, state) do
    state = resize(width, height, state)
    {:noreply, state}
  end

  def handle_event(event, state) do
    IO.puts("Unhandled event: #{inspect event}")
    {:noreply, state}
  end

  def handle_sync_event({:wx, _, _, _, {:wxPaint, :paint}}, _ref, state) do
    handle_key_events(state)
    :wx.batch(fn -> render(state) end)
    :ok
    #{:noreply, state}
  end

  def terminate(_message, state) do
    :timer.cancel(state.timer)
    :timer.sleep(300)
  end

  # Keyboard handling function. Note that this is called in the loop so
  # farm of the actual handling to a different process ASAP.
  defp handle_key_events(state) do
    Enum.map(state.keymap, fn({key, {mod, fun, args}}) ->
      if :wx_misc.getKeyState(key) do
        Task.start(mod, fun, args)
      end
    end)
  end

  # Private drawing functions - this is where all the WX calls get
  # made

  def force_repaint(state) do
    # Force a refresh so that `render` gets triggered through a paint event.
    :wxWindow.refresh(state.frame, [eraseBackground: false])
  end

  def render(state) do
    # Managed double buffering. We draw on an in-memory
    # bitmap and send that to the paint dc in one call.
    mdc = :wxMemoryDC.new()
    :wxMemoryDC.selectObject(mdc, state.buffer)
    :wxDC.setBackground(mdc, :wxBrush.new({50, 50, 50}))
    :wxDC.clear(mdc)
    :wxDC.setUserScale(mdc, state.scale.x, state.scale.y)
    draw_entities(state, mdc)
    :wxMemoryDC.destroy(mdc)

    pdc = :wxPaintDC.new(state.frame)
    :wxDC.drawBitmap(pdc, state.buffer, {0, 0})
    :wxPaintDC.destroy(pdc)
  end

  defp resize(_width, _height, state) do
    {width, height} = :wxWindow.getClientSize(state.frame)
    buffer = :wxBitmap.new(width, height)
    scale = %{
      x: width / @field_width,
      y: height / @field_height
    }
    %State{state | buffer: buffer, scale: scale}
  end

  defp draw_entities(state, dc) do
    state.registry
      |> Registry.get_all_for_component(:render)
      |> Enum.map(&draw_entity(&1, dc))
  end

  defp draw_entity(entity_pid, dc) do
    # Entities that can be rendered should have a position. We fetch a snapshot
    # of both and send that to the entity's render component.
    [position, render] = Entity.get_components(entity_pid, [:position, :render])
    Component.apply(render, :render, [position, dc])
  end

  # Event catchalls

  def handle_cast(msg, state) do
    IO.puts("handle_cast(#{inspect msg}, #{inspect state})")
    {:noreply, state}
  end

  def handle_call(msg, _from, state) do
    IO.puts("handle_call(#{inspect msg}, #{inspect state})")
    {:reply, :ok, state}
  end
end
