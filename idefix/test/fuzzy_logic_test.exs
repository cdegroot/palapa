defmodule FuzzyLogicTest do
  use ExUnit.Case, async: true

  alias Idefix.FuzzyLogic, as: FL

  test "Simple AND and OR" do
    input1 = [too_cold: 0.6]
    input2 = [temp_falling: 0.4]

    # If too_cold AND temp_falling then heat_high
    and_rule = FL.fzand(:too_cold, :temp_falling, heater: :high)
    # IF too_cold OR temp_falling then heat_low
    or_rule  = FL.fzor(:too_cold, :temp_falling, heater: :low)

    assert {[heater: :high], 0.4} == and_rule.(input1, input2)
    assert {[heater: :low], 0.6} == or_rule.(input1, input2)
  end

  test "Combine outputs" do
    snippets = [
      {[heater: :high], 0.4},
      {[heater: :low], 0.2},
      {[heater: :off], 0.1},
      {[fan: :on], 0.4},
      {[fan: :off], 0.2},
    ]
    combined = %{
      heater: [off: 0.1, low: 0.2, high: 0.4],
      fan:    [off: 0.2, on: 0.4]
    }
    assert combined == FL.combine(snippets)
  end
end
