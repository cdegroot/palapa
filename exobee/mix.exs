defmodule Exobee.MixProject do
  use Mix.Project

  def project do
    [
      app: :exobee,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:jason, "~> 1.1"},
      {:majordomo_vault, path: "../majordomo-vault"}
    ]
  end
end
