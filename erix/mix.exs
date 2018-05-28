defmodule Erix.Mixfile do
  use Mix.Project

  def project do
    [app: :erix,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:exleveldb, "~> 0.11.0"},
     {:simpler, in_umbrella: true}]
  end
end
