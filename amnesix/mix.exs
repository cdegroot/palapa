defmodule Amnesix.Mixfile do
  use Mix.Project

  def project do
    [app: :amnesix,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [extra_applications: [:logger, :brod],
     mod: {Amnesix.Application, []}]
  end

  defp deps do
    [{:brod, "~> 2.2"},
     {:simpler, path: "../simpler"}]
  end
end
