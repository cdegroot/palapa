defmodule FuzzyLogicTest do
  use ExUnit.Case, async: true

  alias Idefix.FuzzyLogic, as: FL

  test "Simple AND and OR" do
    input1 = [too_cold: 0.6]
    input2 = [temp_falling: 0.4]

    # If too_cold AND temp_falling then heat_high
    and_rule = FL.fzand(:too_cold, :temp_falling, :heat_high)
    # IF too_cold OR temp_falling then heat_low
    or_rule  = FL.fzor(:too_cold, :temp_falling, :heat_low)

    assert [heat_high: 0.4] == and_rule.(input1, input2)
    assert [heat_low: 0.6] == or_rule.(input1, input2)
  end
end
