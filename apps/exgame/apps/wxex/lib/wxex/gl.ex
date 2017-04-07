defmodule WxEx.GL do
  @moduledoc """
    Build a GL primitive. The body is enclosed in a list
    of primitives. This is a very simple macro that just
    removes some of the syntactical ugliness and improves
    readability.
  """
  defmacro gl_primitive(type, body) do
    # This is how the type gets passed in, apparently.
    {:__aliases__, _context, [type_atom]} = type
    # If type is passed in as an atom, Elixir will prepend "Elixir." to it. Handle that here.
    const = "c_#{type_atom}"
      |> String.replace("Elixir.", "")
      |> String.to_atom
    primitive_type = apply(:gl_const, const, [])
    quote do
      :gl.'begin'(unquote(primitive_type))
      unquote(body)
      :gl.'end'()
    end
  end
end
