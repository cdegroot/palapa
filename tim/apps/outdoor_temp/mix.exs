defmodule OutdoorTemp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :outdoor_temp,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {OutdoorTemp, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
    ]
  end
end
