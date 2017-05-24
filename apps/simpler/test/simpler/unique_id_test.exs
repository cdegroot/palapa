defmodule Simpler.UniqueIdTest do
  use ExUnit.Case, async: true

  alias Simpler.UniqueId

  test "Unique ID basics" do
    id = UniqueId.unique_id()
    string_id = UniqueId.to_string(id)
    assert UniqueId.from_string(string_id) == id

    id_string = UniqueId.unique_id_string()
    id = UniqueId.from_string(id_string)
    assert UniqueId.to_string(id) == id_string
  end
end
