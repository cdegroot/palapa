defmodule Exobee.Thermostat do
  @moduledoc "Thermostat functions"

  alias Exobee.{Secrets, Api}

  def list do
    # TODO paging

    {:ok, access_token} = Secrets.access_token()
    body = %{selection: %{selectionType: "registered", selectionMatch: "", includeRuntime: true}}
    |> Jason.encode!()
    {:ok, body} = Api.get("1/thermostat?format=json&body=#{body}",
      %{"Content-Type": "text/json",
        "Authorization": "Bearer #{access_token}"})
    body["thermostatList"]
  end
end
