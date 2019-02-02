defmodule Exobee.TokenManagement do
  @moduledoc """
  This module handles all the interaction with the Ecobee API and
  MajordomoVault to manage tokens, schedule refreshes, etcetera
  """

  # TODO schedule refresh
  # TODO check whether running the PIN protocol is needed.

  @doc """
  Get a PIN from Ecobee and display it to the user. Then poll until
  we get an auth code we can stash in MajordomoVault.
  """
  def run_pin_protocol() do
    {:ok, app_key} = application_key()
    {:ok, response} = HTTPoison.get("https://api.ecobee.com/authorize?response_type=ecobeePin&client_id=#{app_key}&scope=smartRead")
    {:ok, body} = Jason.decode(response.body)
    IO.inspect(body)
    IO.puts("Please enter this pin code in the portal: #{body["ecobeePin"]}")
    poll_interval = body["interval"] * 1_000
    attempts = round(body["expires_in"] * 60 / body["interval"])
    start_poll(poll_interval, app_key, body["code"], attempts)
  end

  defp start_poll(_sleep_time, _app_key, _code, 0) do
    IO.puts("Could not complete authentication in time, please try again")
  end
  defp start_poll(sleep_time, app_key, code, attempts_left) do
    IO.puts("Sleeping until next poll...")
    Process.sleep(sleep_time)
    {:ok, response} = HTTPoison.post("https://api.ecobee.com/token?grant_type=ecobeePin&code=#{code}&client_id=#{app_key}", "")
    {:ok, body} = Jason.decode(response.body)
    if Map.has_key?(body, "error") do
      IO.puts("Authentication incomplete, reason: #{body["error_description"]}")
      start_poll(sleep_time, app_key, code, attempts_left - 1)
    else
      IO.inspect(body)
      access_token = body["access_token"]
      refresh_token = body["refresh_token"]
      expires_in = body["expires_in"]
      # TODO start something for refresh
      MajordomoVault.put!({Exobee, :access_token}, access_token)
      MajordomoVault.put!({Exobee, :refresh_token}, refresh_token)
      IO.puts("Stored access and refresh tokens, all good")
    end
  end

  defp application_key() do
    key = MajordomoVault.get({Exobee, :application_key})
    if key == nil do
      {:error, "Configure the Exobee application key first"}
    else
      {:ok, key}
    end
  end
end
