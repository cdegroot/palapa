defmodule Control do
  defdelegate get_state, to: Control.State
  defdelegate toggle, to: Control.State
end
