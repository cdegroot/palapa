defmodule NervesScenic.Scene.SysInfo do
  use Scenic.Scene
  alias Scenic.Graph

  import Scenic.Primitives

  @target System.get_env("MIX_TARGET") || "host"

  @system_info """
  MIX_TARGET: #{@target}
  MIX_ENV: #{Mix.env()}
  Scenic version: #{Scenic.version()}
  """

  @iex_note """
  Please note: because Scenic draws over
  the entire screen in Nerves, IEx has
  been routed to the UART pins.
  """

  @graph Graph.build(font_size: 22, font: :roboto_mono)
         |> group(
           fn g ->
             g
             |> text("System")
             |> text(@system_info, translate: {10, 20}, font_size: 18)
           end,
           t: {10, 30}
         )
         |> group(
           fn g ->
             g
             |> text("ViewPort")
             |> text("", translate: {10, 20}, font_size: 18, id: :vp_info)
           end,
           t: {10, 110}
         )
         |> group(
           fn g ->
             g
             |> text("Input Devices")
             |> text("Devices are being loaded...",
               translate: {10, 20},
               font_size: 18,
               id: :devices
             )
           end,
           t: {280, 30},
           id: :device_list
         )
         |> group(
           fn g ->
             g
             |> text("IEx")
             |> text(@iex_note, translate: {10, 20}, font_size: 18)
           end,
           t: {10, 240}
         )

  # --------------------------------------------------------
  def init(_, opts) do
    {:ok, info} = Scenic.ViewPort.info(opts[:viewport])

    vp_info = """
    size: #{inspect(Map.get(info, :size))}
    """

    # styles: #{stringify_map(Map.get(info, :styles, %{a: 1, b: 2}))}
    # transforms: #{stringify_map(Map.get(info, :transforms, %{}))}
    # drivers: #{stringify_map(Map.get(info, :drivers))}

    graph =
      @graph
      |> Graph.modify(:vp_info, &text(&1, vp_info))
      |> Graph.modify(:device_list, &update_opts(&1, hidden: @target == "host"))
      |> push_graph()

    unless @target == "host" do
      # subscribe to the simulated temperature sensor
      Process.send_after(self(), :update_devices, 100)
    end

    {:ok, graph}
  end

  unless @target == "host" do
    # --------------------------------------------------------
    # Not a fan of this being polling. Would rather have InputEvent send me
    # an occasional event when something changes.
    def handle_info(:update_devices, graph) do
      Process.send_after(self(), :update_devices, 1000)

      devices =
        InputEvent.enumerate()
        |> Enum.reduce("", fn {_, device}, acc ->
          Enum.join([acc, inspect(device), "\r\n"])
        end)

      # update the graph
      graph =
        graph
        |> Graph.modify(:devices, &text(&1, devices))
        |> push_graph()

      {:noreply, graph}
    end
  end
end
