defmodule Simpler.Mixfile do
  use Mix.Project

  def project do
    [app: :simpler,
     version: "0.2.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "Tools for making testing simpler",
     package: package(),
     deps: deps(),
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    # Policy dependencies: stuff that isn't required but we
    # want to be always available in stuff using Simpler.
    [{:credo, "~> 0.7", only: [:dev, :test]},
     {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
     {:excoveralls, "~> 0.6", only: :test},
     {:ex_doc, ">= 0.0.0", only: :dev}]
    # No other dependencies - that's a bit of a design goal for now
  end

  defp package do
    [
      maintainers: ["Cees de Groot"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/cdegroot/palapa/tree/master/apps/simpler",
               "Docs" => "http://hexdocs.pm/simpler"}]
  end
end
