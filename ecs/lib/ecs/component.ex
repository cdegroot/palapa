defmodule ECS.Component do
  @moduledoc """
  The Component part of Entity-Component-System. Represented as a struct
  containing the value of the component.
  """

  defmacro component_fields(fields) do
    quote do
      defstruct unquote(fields)

      @spec new :: %unquote(__CALLER__.module){}
      def new do
        struct(unquote(__CALLER__.module))
      end
      @spec new(Enum.t) :: %unquote(__CALLER__.module){}
      def new(args) do
        struct(unquote(__CALLER__.module), args)
      end
    end
  end

  @doc """
  Call a function on a component. The component itself will
  be added as a first argument.
  """
  def apply(component, function, args) do
    Kernel.apply(component.__struct__, function, [component | args])
  end
end
