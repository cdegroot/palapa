defmodule Hnte.Constructor do
  @doc """
  Cosntruct the genotype for the specified NN. The genotype is an Elixir module
  with a single `genotype` function because that's human readable and should be
  simple to compile :-).

  We expand on the book a bit because in Elixir it's probably more natural to
  have module names instead of symbols with case statements for actuators
  and sensors.
  """
  def generate(module_name, sensor_module, actuator_module, layers_spec) do
    # Generate sensor and actuator constructors
    sensor_id = make_id()
    actuator_id = make_id()
    cortex_id = make_id()
    sensor = make_sensor(sensor_id, sensor_module)
    actuator = make_actuator(actuator_id, actuator_module)
    layer_densities = layers_spec ++ [actuator.vl]
    neurons = make_neurons(cortex_id, sensor, actuator, layer_densities)
    cortex = "TODO MAKE CORTEX"

    statements = quote do
      defmodule unquote(module_name) do
        def genotype() do
          [
            unquote(sensor),
            unquote_splicing(neurons),
            unquote(actuator),
            unquote(cortex)
          ]
        end
      end
    end
    Macro.to_string(statements)
  end

  def make_sensor(id, module) do
    vl = module.vl()
    %{type: :sensor, id: id, module: module, vl: vl}
  end

  def make_actuator(id, module) do
    vl = module.vl()
    %{type: :actuator, id: id, module: module, vl: vl}
  end

  def make_neurons(cortex_id, sensor, actuator, layer_densities) do
    input_idps = [{sensor.id, sensor.vl}]
    tot_layers = length(layer_densities)
    [fl_neurons | next_lds] = layer_densities
    neuron_ids = make_nids(fl_neurons, 1)
    make_neurons(cortex_id, actuator.id, 1, tot_layers, input_idps, neuron_ids, next_lds, [])
  end

  def make_neurons(cortex_id, actuator_id, layer_index, tot_layers, input_idps, nids,
               [next_ld | lds], acc) do
    output_nids = make_nids(next_ld, layer_index)
    layer_neurons = make_neurons(cortex_id, input_idps, nids, output_nids, [])
    next_input_idps = Enum.map(nids, fn nid -> {nid, 1} end)
    make_neurons(cortex_id, actuator_id, layer_index + 1, tot_layers, next_input_idps,
      output_nids, lds, [layer_neurons | acc])
  end

  def make_neurons(cortex_id, actuator_id, tot_layers, tot_layers, input_idps,
                   nids, [], acc) do
    output_ids = [actuator_id]
    layer_neurons = make_neurons(cortex_id, input_idps, nids, output_ids, [])
    :lists.reverse([layer_neurons | acc])
  end

  def make_neurons(cortex_id, input_idps, [id | nids], output_ids, acc) do
    neuron = make_neuron(input_idps, id, cortex_id, output_ids)
    make_neurons(cortex_id, input_idps, nids, output_ids, [neuron | acc])
  end
  def make_neurons(_cortex_id, _input_idps, [], _output_ids, acc) do
    acc
  end

  def make_neuron(input_idps, id, cortex_id, output_ids) do
    inputs = Enum.map(input_idps, fn {input_id, input_vl} ->
      weights = Enum.map(1..input_vl, fn _ -> :rand.uniform() - 0.5 end)
      {input_id, weights}
    end)
    %{type: :neuron, id: id, input_idps: inputs, output_ids: output_ids, af: &:math.tanh/1}
  end

  defp make_id() do
    "node_#{:erlang.unique_integer([:positive])}"
  end

  defp make_nids(n, layer_id) do
    Enum.map(1..n, fn _ -> {layer_id, make_id()} end)
  end
end
