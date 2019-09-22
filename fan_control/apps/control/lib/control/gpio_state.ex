defmodule Control.GpioState do
  require Logger

  @pin 17

  def start_link(_initial) do
    ElixirALE.GPIO.start_link(@pin, :output, start_value: false, name: __MODULE__)
  end

  def get_state do
    ElixirALE.GPIO.read(__MODULE__)
  end

  def toggle do
    value = if get_state(), do: false, else: true
    ElixirALE.GPIO.write(__MODULE__, value)
  end
end
