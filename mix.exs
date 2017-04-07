defmodule Palapa.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp deps do
    [{:excoveralls, "~> 0.6", only: :test},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
     {:mix_test_watch, "~> 0.3", only: :dev}]
  end
end
