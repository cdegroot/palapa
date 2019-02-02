defmodule ExobeeTest do
  use ExUnit.Case

  #test "Can run the PIN protocol" do
    #Exobee.init_secrets()
  #end

  test "Can fetch current temp" do
    list = Exobee.Thermostat.list()
    assert length(list) == 1
  end
end
