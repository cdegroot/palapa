defmodule Idefix.MembershipTriangle do
  @moduledoc """
  Triangle based membership functions for fuzzy logic. This is a very
  basic membership function where you pass in a set of labels and center
  values; the triangles will reach zero right under their neighbour's
  center values.
  """

  @doc """
  Make a new triangle-based membership function. The return value is opaque and
  should be passed in to the other functions. (todo: polymorphism)
  """
  def new(values) do
    [{:dummy, :neg_inf} | values] ++ [{:dummy, :pos_inf}]
    |> Enum.chunk_every(3, 1, :discard)
    |> Enum.map(fn [{_ignore1, left}, {label, center}, {_ignore2, right}] ->
      make_partial(label, left, center, right)
    end)
  end

  @doc """
  Returns membership values as a list of {label: [0..1]} values.
  """
  def membership(f, value) do
    Enum.map(f, fn {label, function} ->
      {label, function.(value)}
    end)
  end

  defp make_partial(label, :neg_inf, center, right) do
    {label, fn
      v when v < center -> 1
      v when v > right  -> 0
      v -> (right - v) / (right - center)
    end}
  end
  defp make_partial(label, left, center, :pos_inf) do
    {label, fn
      v when v < left -> 0
      v when v > center -> 1
      v -> (v - left) / (center - left)
    end}
  end
  defp make_partial(label, left, center, right) do
    {label, fn
      v when v < left -> 0
      v when v > right -> 0
      v when v < center -> (v - left) / (center - left)
      v -> (right - v) / (right - center)
     end}
  end
end
