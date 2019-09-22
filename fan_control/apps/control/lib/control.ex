defmodule Control do
  defdelegate get_state, to: Control.State
  defdelegate set_state, to: Control.State
end
