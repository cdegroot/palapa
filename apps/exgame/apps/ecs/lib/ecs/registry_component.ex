defmodule ECS.RegistryComponent do
  @moduledoc """
  A component that keeps a link to a registry. It's added by default to Entity
  if a registry is passed in.
  """
  import ECS.Component
  component_fields [:value]
end
