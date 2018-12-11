defmodule Hnte.SimpleNeuron do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  @doc """
  Run a signal through the neuron. Result is the output value as a list.
  """
  def sense(pid, values) do
    GenServer.call(pid, {:sense, values})
  end

  def init([]) do
    weights = Enum.map(1..3, fn _ -> :rand.uniform() - 0.5 end)
    {:ok, weights}
  end

  def handle_call({:sense, values}, _from, state) do
    Logger.info("Processing input #{inspect values}")
    Logger.info("Current weights: #{inspect state}")
    dot_product = dot(values, state, 0)
    output = [:math.tanh(dot_product)]
    Logger.info("Output: #{inspect output}")
    {:reply, output, state}
  end

  # This dot product assumes that the bios is the last weight.
  defp dot([input | inputs], [weight | weights], acc) do
    dot(inputs, weights, (input * weight) + acc)
  end
  defp dot([], [bias], acc) do
    bias + acc
  end
end
