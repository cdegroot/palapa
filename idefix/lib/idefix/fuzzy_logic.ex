defmodule Idefix.FuzzyLogic do
  @moduledoc """
  The actual fuzzy logic functions AND and OR

  Our sets are {label, value} tuples and the output is again a {label, value} tuple.
  """

  @doc """
  Fuzzy AND through the minimum function
  """
  def fzand(left_label, right_label, output_label) do
    mkfun(&min/2, left_label, right_label, output_label)
  end

  @doc """
  Fuzzy OR through the maximum function
  """
  def fzor(left_label, right_label, output_label) do
    mkfun(&max/2, left_label, right_label, output_label)
  end

  def mkfun(function, left_label, right_label, output_label) do
    fn (left_set, right_set) ->
      lhs = Keyword.get(left_set, left_label)
      rhs = Keyword.get(right_set, right_label)
      [{output_label, function.(lhs, rhs)}]
    end
  end
end
