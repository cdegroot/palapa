defmodule Idefix.FuzzyLogic do
  @moduledoc """
  The actual fuzzy logic functions AND and OR

  Our sets are {label, value} tuples and the output is again a {label, value} tuple.
  """

  @doc """
  TODO: top level function. We define fuzzyfication rules (through the Triangle
  membership functions with a definition per input) and logic rules. After the
  logic rules, a set of labels and values is left; these are combined per label
  through the center-of-gravity method to return an output value per label.

  The return value is a function that will take inputs (in the same order as the
  fuzzification rules), applies the logic rules, and then combines the output.

  """
  def fuzzy_logic(input_rules, _logic_rules) do
    fn values ->
      _fuzzied = values
      |> Enum.zip(input_rules)
      |> Enum.map(fn value, rule ->
        Idefix.MembershipTriangle.membership(rule, value)
      end)
      # Now run this through all the logic rules
      # .. combine the result
      # .. and calculate CoG for each element in that map
    end
  end

  @doc """
  Fuzzy AND through the minimum function
  """
  def fzand(left_label, right_label, output) do
    mkfun(&min/2, left_label, right_label, output)
  end

  @doc """
  Fuzzy OR through the maximum function
  """
  def fzor(left_label, right_label, output) do
    mkfun(&max/2, left_label, right_label, output)
  end

  @doc """
  Given a bunch of `{{label, value}, score}` tuples, sort everything by label.
  """
  def combine(snippets) do
    snippets
    |> Enum.reduce(%{}, fn({[{label, value}], score}, acc) ->
      Map.update(acc, label, [{value, score}], fn vals -> [{value, score} | vals] end)
    end)
  end

  def mkfun(function, left_label, right_label, output) do
    fn (left_set, right_set) ->
      lhs = Keyword.get(left_set, left_label)
      rhs = Keyword.get(right_set, right_label)
      {output, function.(lhs, rhs)}
    end
  end
end
