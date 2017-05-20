defmodule Simpler.UniqueIdTest do
  use ExUnit.Case, async: true

  alias Simpler.UniqueId

  test "Unique ID basics" do
    id = UniqueId.unique_id()
    string_id = UniqueId.to_string(id)
    assert UniqueId.from_string(string_id) == id
  end
end
