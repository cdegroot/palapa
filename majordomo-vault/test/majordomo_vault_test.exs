defmodule MajordomoVaultTest do
  use ExUnit.Case
  doctest MajordomoVault

  test "Works as advertised" do
    # Note that this is an integration test and will write the actual file.
    random = :crypto.strong_rand_bytes(16)
    MajordomoVault.put!({MajordomoVaultTest, :integration_test}, random)

    assert MajordomoVault.get({MajordomoVaultTest, :integration_test}) == random

  end
end
