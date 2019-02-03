defmodule Exobee.TokenManagement do
  @moduledoc """
  This module handles all the interaction with the Ecobee API and
  MajordomoVault to manage tokens, schedule refreshes, etcetera
  """

  alias Exobee.Api
  alias Exobee.Secrets
  require Logger

  @doc """
  Refresh tokens.
  """
  def refresh() do
    {:ok, app_key} = Secrets.application_key()
    {:ok, refresh_token} = Secrets.refresh_token()

    {:ok, body} = Api.post("token?grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{app_key}")
    if Map.has_key?(body, "error") do
      Logger.info("Refresh incomplete, reason: #{body["error_description"]}")
      {:error, body["error_description"]}
    else
      store_secrets_from_body(body)
      Logger.info("Stored access and refresh tokens, all good")
    end
  end

  @doc """
  Get a PIN from Ecobee and display it to the user. Then poll until
  we get an auth code we can stash in MajordomoVault.
  """
  def run_pin_protocol() do
    {:ok, app_key} = Secrets.application_key()
    {:ok, body} = Api.get("authorize?response_type=ecobeePin&client_id=#{app_key}&scope=smartRead")
    Logger.info("Please enter this pin code in the portal: #{body["ecobeePin"]}")
    poll_interval = body["interval"] * 1_000
    attempts = round(body["expires_in"] * 60 / body["interval"])
    start_poll(poll_interval, app_key, body["code"], attempts)
  end

  defp start_poll(_sleep_time, _app_key, _code, 0) do
    Logger.info("Could not complete authentication in time, please try again")
  end
  defp start_poll(sleep_time, app_key, code, attempts_left) do
    Logger.info("Sleeping until next poll...")
    Process.sleep(sleep_time)
    {:ok, body} = Api.post("token?grant_type=ecobeePin&code=#{code}&client_id=#{app_key}")
    if Map.has_key?(body, "error") do
      Logger.info("Authentication incomplete, reason: #{body["error_description"]}")
      start_poll(sleep_time, app_key, code, attempts_left - 1)
    else
      store_secrets_from_body(body)
      Logger.info("Stored access and refresh tokens, all good")
    end
  end

  defp store_secrets_from_body(body) do
    Secrets.update_refresh_token(body["refresh_token"])
    Secrets.update_access_token(body["access_token"])
  end
end
