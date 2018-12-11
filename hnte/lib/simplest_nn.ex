defmodule Hnte.SimplestNn do

  # Note - we're going with OTP all the things. It may or may not be the wisest
  # thing to do, but I feel it's sensible as it keeps code understandable by
  # staying close to standard, OTP-loving, Elixir

  defmodule Node do
    def input(neuron, values) do
      GenServer.cast(neuron, {:input, values})
    end
  end

  defmodule Neuron do
    use GenServer
    require Logger

    defmodule State do
      defstruct [:weights, :input, :output]
    end

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def connect(neuron, input, output) do
      GenServer.cast(neuron, {:connect, input, output})
    end

    def init([]) do
      weights = Enum.map(1..3, fn _ -> :rand.uniform() - 0.5 end)
      {:ok, %State{weights: weights}}
    end

    def handle_cast({:connect, input, output}, state) do
      {:noreply, %State{state | input: input, output: output}}
    end

    def handle_cast({:input, values}, state) do
      Logger.info("Processing input #{inspect values}")
      Logger.info("Current weights: #{inspect state.weights}")
      dot_product = dot(values, state.weights, 0)
      output = [:math.tanh(dot_product)]
      Logger.info("Output: #{inspect output}")
      Hnte.SimplestNn.Node.input(state.output, output)
      {:noreply, state}
    end

    # This dot product assumes that the bios is the last weight.
    defp dot([input | inputs], [weight | weights], acc) do
      dot(inputs, weights, (input * weight) + acc)
    end
    defp dot([], [bias], acc) do
      bias + acc
    end
  end

  defmodule Actuator do
    use GenServer
    require Logger

    def start_link(neuron) do
      GenServer.start_link(__MODULE__, neuron)
    end

    def init(neuron) do
      {:ok, neuron}
    end
    def handle_cast({:input, values}, state) do
      Logger.info("Actuator got #{inspect values}")
      {:noreply, state}
    end
  end

  defmodule Sensor do
    use GenServer
    require Logger

    def start_link(neuron) do
      GenServer.start_link(__MODULE__, neuron)
    end
    def trigger(sensor) do
      GenServer.cast(sensor, :trigger)
    end

    def init(neuron) do
      {:ok, neuron}
    end

    def handle_cast(:trigger, state) do
      sensed_values = Enum.map(1..2, fn _ -> :rand.uniform() end)
      Logger.info("Sensor sensed #{inspect sensed_values}")
      Hnte.SimplestNn.Node.input(state, sensed_values)
      {:noreply, state}
    end
  end

  defmodule Cortex do
    require Logger

    def start_link do
      {:ok, neuron} = Hnte.SimplestNn.Neuron.start_link()
      {:ok, sensor} = Hnte.SimplestNn.Sensor.start_link(neuron)
      {:ok, actuator} = Hnte.SimplestNn.Actuator.start_link(neuron)
      Logger.info("n=#{inspect neuron}, s=#{inspect sensor}, a=#{inspect actuator}")
      Hnte.SimplestNn.Neuron.connect(neuron, sensor, actuator)
      {:ok, sensor}
    end
  end
end
