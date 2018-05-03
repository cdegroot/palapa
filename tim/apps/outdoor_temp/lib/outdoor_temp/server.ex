defmodule OutdoorTemp.Server do
  @rtl_433_cmd "rtl_433 -R 73"

  use GenServer
  require Logger

  defmodule State do
    defstruct [:port, :id, :callbacks]
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # TODO unregister?
  def register(callback_module) do
    GenServer.cast(__MODULE__, {:register, callback_module})
  end

  ## Server side

  def init([]) do
    Logger.info("Starting rtl_433 reader")
    port = Port.open({:spawn, @rtl_433_cmd}, [{:line, 132}, :stderr_to_stdout, :exit_status])
    {:ok, %State{port: port, id: nil, callbacks: []}}
  end

  def handle_inf({:register, callback}, state) do
    {:noreply, %State{state | callbacks: [callback | state.callbacks]}}
  end
  
  def handle_info({_port, {:data, {:eol, '\tSensor ID:\t ' ++ sensor_id}}}, state) do
    {:noreply, %State{state | id: to_string(sensor_id)}}
  end

  def handle_info({_port, {:data, {:eol, '\tTemperature:\t ' ++ temp}}}, state) do
    # We get a charlist with 'x.x C' here
    temp = temp
    |> to_string
    |> String.split(" ")
    |> hd
    |> String.to_float
    Logger.info("  temp for #{state.id} is #{inspect temp}")
    send_events(state.id, temp, state.callbacks)
    {:noreply, state}
  end

  def handle_info({_port, {:exit_status, status}}, state) do
    Logger.error("rtl_433 bailed out with #{status}, exiting")
    {:stop, "rtl_433 exited with #{status}", state}
  end

  def handle_info(msg, state) do
    Logger.debug(" ignore #{inspect msg}")
    {:noreply, state}
  end

  defp send_events(id, temp, callback_modules) do
    callback_modules 
    |> Enum.map(fn(callback_module) ->
      callback_module.outdoor_temp_event(id, temp)
    end)
  end
end
