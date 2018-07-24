defmodule MembershipTriangleTest do
  use ExUnit.Case, async: true

  alias Idefix.MembershipTriangle, as: F

  test "Membership values when on center points" do
    f = make_triangles()
    assert F.membership(f, 10) == [too_cold: 1.0, cold: 0.0, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 15) == [too_cold: 0.0, cold: 1.0, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 20) == [too_cold: 0.0, cold: 0.0, optimal: 1.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 25) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 1.0, too_hot: 0.0]
    assert F.membership(f, 30) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 0.0, too_hot: 1.0]
  end

  test "Membership values when on halfway points" do
    f = make_triangles()
    assert F.membership(f, 12.5) == [too_cold: 0.5, cold: 0.5, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 17.5) == [too_cold: 0.0, cold: 0.5, optimal: 0.5, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 22.5) == [too_cold: 0.0, cold: 0.0, optimal: 0.5, hot: 0.5, too_hot: 0.0]
    assert F.membership(f, 27.5) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 0.5, too_hot: 0.5]
  end

  test "Membership outside the regular range" do
    f = make_triangles()
    assert F.membership(f, 0) == [too_cold: 1.0, cold: 0.0, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 500) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 0.0, too_hot: 1.0]
  end

  test "Membership values between points on left end of spectrum" do
    f = make_triangles()
    assert F.membership(f, 10) == [too_cold: 1.0, cold: 0.0, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 11) == [too_cold: 0.8, cold: 0.2, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 12) == [too_cold: 0.6, cold: 0.4, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 13) == [too_cold: 0.4, cold: 0.6, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 14) == [too_cold: 0.2, cold: 0.8, optimal: 0.0, hot: 0.0, too_hot: 0.0]
    assert F.membership(f, 15) == [too_cold: 0.0, cold: 1.0, optimal: 0.0, hot: 0.0, too_hot: 0.0]
  end

  test "Membership values between points on right end of spectrum" do
    f = make_triangles()
    assert F.membership(f, 25) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 1.0, too_hot: 0.0]
    assert F.membership(f, 26) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 0.8, too_hot: 0.2]
    assert F.membership(f, 27) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 0.6, too_hot: 0.4]
    assert F.membership(f, 28) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 0.4, too_hot: 0.6]
    assert F.membership(f, 29) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 0.2, too_hot: 0.8]
    assert F.membership(f, 30) == [too_cold: 0.0, cold: 0.0, optimal: 0.0, hot: 0.0, too_hot: 1.0]
  end

  defp make_triangles do
    Idefix.MembershipTriangle.new([too_cold: 10, cold: 15, optimal: 20, hot: 25, too_hot: 30])
  end

end
