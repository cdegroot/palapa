defmodule Control do
  if Mix.target == :host do
    @control_module Control.FakeState
  else
    @control_module Control.GpioState
  end
  def control_module, do: @control_module

  defdelegate get_state, to: @control_module
  defdelegate toggle, to: @control_module
end
