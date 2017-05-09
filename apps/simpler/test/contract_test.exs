defmodule Simpler.ContractTest do
  use ExUnit.Case, async: true

  defmodule SimplePre do
    use Simpler.Contract
    precondition do: op_one > op_two
    def mymethod(op_one, op_two) do
      op_one - op_two
    end
    def nextmethod(op_one, op_two) do
      op_one + op_two
    end
  end
  test "Contracted method accepts preconditions" do
    assert SimplePre.mymethod(4, 2) == 2
  end
  test "Next method doesn't inherit preconditions" do
    assert SimplePre.nextmethod(2, 4) == 6
  end
  test "Contracted method reject :33
  bad precondition" do
    try do
      SimplePre.mymethod(2, 4)
      raise "assertion didn't trigger!"
    rescue
      _e in [ExUnit.AssertionError] -> nil
      e -> raise(e)
    end
  end

  defmodule SimplePost do
    use Simpler.Contract
    postcondition do: result > 0
    def mymethod(op_one, op_two) do
      op_one - op_two
    end
    def nextmethod(op_one, op_two) do
      op_one + op_two
    end
  end
  test "Contracted method accepts postcondition" do
    assert SimplePost.mymethod(4, 2) == 2
  end
  test "Next method doesn't inherit postonditions" do
    assert SimplePre.nextmethod(-2, -4) == -6
  end
  test "Contract method rejects postcondition" do
    try do
      SimplePost.mymethod(2, 4)
      raise "assertion didn't trigger!"
    rescue
      _e in [ExUnit.AssertionError] -> nil
      e -> raise(e)
    end
  end

  defmodule MultipleHeads do
    use Simpler.Contract
    precondition do: op_two < 10
    postcondition do: result > 0
    def method(:one, op_two) do
      10 + op_two
    end
    def method(:two, op_two) do
      20 + op_two
    end
    def method(op_one, op_two) do
      30 + op_two
    end
  end
  test "Multiple function heads work" do
    assert MultipleHeads.method(:one, 1) == 11
  end
end
