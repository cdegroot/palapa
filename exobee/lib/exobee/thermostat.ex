defmodule Exobee.Thermostat do
  @moduledoc "Thermostat functions"

  def list do
    # TODO refresh and retry.
    # TODO paging

    access_token = MajordomoVault.get({Exobee, :access_token})
    body = %{selection: %{selectionType: "registered", selectionMatch: "", includeRuntime: true}}
    |> Jason.encode!()
    {:ok, response} = HTTPoison.get("https://api.ecobee.com/1/thermostat?format=json&body=#{body}",
      %{"Content-Type": "text/json",
        "Authorization": "Bearer #{access_token}"})
    {:ok, body} = Jason.decode(response.body)
    body["thermostatList"] |> IO.inspect
  end
end
