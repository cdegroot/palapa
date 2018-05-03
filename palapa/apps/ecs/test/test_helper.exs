ExUnit.start()

defmodule AgeComponent do
  import ECS.Component
  component_fields [:value]
end
