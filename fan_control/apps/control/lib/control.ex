defmodule Control do
  if Mix.target == :host do
    defdelegate get_state, to: Control.FakeState
    defdelegate toggle, to: Control.FakeState
  else
    defdelegate get_state, to: Control.GpioState
    defdelegate toggle, to: Control.GpioState
  end
end
