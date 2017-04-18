defmodule Erix.Server.LeaderTest do
  use ExUnit.Case, async: true

  alias Erix.Server.Leader

  test "commit_index is calculated correctly when peers update" do
    match_index = %{1 => 42, 2 => 43}
    last_index = 44
    commit_index = 41
    new_index = Leader._calculate_commit_index(match_index, last_index, commit_index)
    assert new_index == 43

    match_index = %{1 => 42, 2 => 41}
    last_index = 44
    commit_index = 41
    new_index = Leader._calculate_commit_index(match_index, last_index, commit_index)
    assert new_index == 42

    match_index = %{1 => 42, 2 => 40, 3 => 39, 4 => 38}
    last_index = 44
    commit_index = 41
    new_index = Leader._calculate_commit_index(match_index, last_index, commit_index)
    assert new_index == 41
  end
end
