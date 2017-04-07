defmodule ECS.IdComponent do
  @moduledoc """
  A component that wraps an id. It's added by default to Entity
  maps.
  """
  import ECS.Component
  component_fields [:value]
end
