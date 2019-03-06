defmodule NervesScenic.Scene.Crosshair do
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph
  alias Scenic.Primitive
  import Scenic.Primitives

  @width 10000
  @height 10000

  @graph Graph.build(font: :roboto, font_size: 16)
         |> rect({@width, @height}, id: :background)
         |> text("Touch the screen to start", id: :pos, translate: {20, 80})
         |> line({{0, 100}, {@width, 100}}, stroke: {4, :white}, id: :cross_hair_h, hidden: true)
         |> line({{100, 0}, {100, @height}}, stroke: {4, :white}, id: :cross_hair_v, hidden: true)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, _) do
    push_graph(@graph)
    {:ok, @graph}
  end

  # ============================================================================
  # event handlers

  # --------------------------------------------------------
  def handle_input({:cursor_button, {:left, :press, _, {x, y}}}, context, graph) do
    graph =
      graph
      |> Graph.modify(:cross_hair_h, fn p ->
        p
        |> Primitive.put({{0, y}, {@width, y}})
        |> Primitive.put_style(:hidden, false)
      end)
      |> Graph.modify(:cross_hair_v, fn p ->
        p
        |> Primitive.put({{x, 0}, {x, @height}})
        |> Primitive.put_style(:hidden, false)
      end)
      |> Graph.modify(:pos, fn p ->
        Primitive.put(
          p,
          "x: #{:erlang.float_to_binary(x * 1.0, decimals: 1)}, y: #{
            :erlang.float_to_binary(y * 1.0, decimals: 1)
          }"
        )
      end)
      |> push_graph()

    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])

    {:noreply, graph}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_button, {:left, :release, _, {x, y}}}, context, graph) do
    graph =
      Graph.modify(graph, :cross_hair_h, fn p ->
        Primitive.put_style(p, :hidden, true)
      end)

    graph =
      Graph.modify(graph, :cross_hair_v, fn p ->
        Primitive.put_style(p, :hidden, true)
      end)
      |> Graph.modify(:pos, fn p ->
        Primitive.put(
          p,
          "x: #{:erlang.float_to_binary(x * 1.0, decimals: 1)}, y: #{
            :erlang.float_to_binary(y * 1.0, decimals: 1)
          }"
        )
      end)
      |> push_graph()

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    {:noreply, graph}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_pos, {x, y}}, _context, graph) do
    graph =
      graph
      |> Graph.modify(:cross_hair_h, fn p ->
        p
        |> Primitive.put({{0, y}, {@width, y}})
      end)
      |> Graph.modify(:cross_hair_v, fn p ->
        p
        |> Primitive.put({{x, 0}, {x, @height}})
      end)
      |> Graph.modify(:pos, fn p ->
        Primitive.put(
          p,
          "x: #{:erlang.float_to_binary(x * 1.0, decimals: 1)}, y: #{
            :erlang.float_to_binary(y * 1.0, decimals: 1)
          }"
        )
      end)
      |> push_graph()

    {:noreply, graph}
  end

  def handle_input(_msg, _, graph) do
    {:noreply, graph}
  end
end
