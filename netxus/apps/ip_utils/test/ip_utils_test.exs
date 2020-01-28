defmodule IpUtilsTest do
  use ExUnit.Case
  doctest IpUtils

  test "IPv4 address testing" do
    refute IpUtils.ipv4?(nil)
    assert IpUtils.ipv4?("1.2.3.4")
    assert IpUtils.ipv4?('1.2.3.4')
    refute IpUtils.ipv4?("fd00::1")
  end

  test "IPv6 address testing" do
    refute IpUtils.ipv6?(nil)
    assert IpUtils.ipv6?("fd00::1")
    refute IpUtils.ipv6?('1.2.3.4')
  end

  test "Converting to PTR" do
    assert IpUtils.ptr("1.2.3.4") == [4, 3, 2, 1]
    assert IpUtils.ptr("fd00::1") == [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xd, 0xf]
  end
end
