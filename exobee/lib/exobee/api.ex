defmodule Exobee.Api do
  @moduledoc """
  Functions that do the HTTP requests and decoding.
  """

  def url(rest) do
    "https://api.ecobee.com/" <> rest
  end

  def get(path), do: get(path, %{})
  def get(path, options), do: get(path, options, 2)
  def get(path, _options, 0) do
    {:error, "No retries left on GET #{path}"}
  end
  def get(path, options, retry_count) do
    url = url(path)
    {:ok, response} = HTTPoison.get(url, options)
    {:ok, body} = Jason.decode(response.body)
    handle_status(body["status"],
      fn -> {:ok, body} end,
      fn -> get(path, options, retry_count - 1) end)
  end

  def handle_status(%{"code" => 0}, success_fun, _retry_fun) do
    success_fun.()
  end
  def handle_status(%{"code" => 14}, _success_fun, retry_fun) do
    # Code 14 means that our token is expired, so refresh and
    # then retry.
    Process.sleep(500)
    Exobee.TokenManagement.refresh()
    Process.sleep(500)
    retry_fun.()
  end
  def handle_status(status, _success_fun, _retry_fun) do
    {:error, "Unknown result #{inspect status}"}
  end

  def post(path), do: post(path, "")
  def post(path, body), do: post(path, body, %{})
  def post(path, body, options) do
    url = url(path)
    {:ok, response} = HTTPoison.post(url, body, options)
    Jason.decode(response.body)
  end
end
