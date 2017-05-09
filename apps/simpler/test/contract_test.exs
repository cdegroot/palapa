defmodule Simpler.ContractTest do
  use ExUnit.Case, async: true

  defmodule SimplePre do
    use Simpler.Contract
    precondition do: op_one > op_two
    def mymethod(op_one, op_two) do
      op_one - op_two
    end
  end
  test "Contracted method accepts preconditions" do
    assert SimplePre.mymethod(4, 2) == 2
  end
  test "Contracted method reject bad precondition" do
    try do
      SimplePre.mymethod(2, 4) == -2
      raise "assertion didn't trigger!"
    rescue
      e in [ExUnit.AssertionError] -> nil
      e -> raise(e)
    end
  end

end
