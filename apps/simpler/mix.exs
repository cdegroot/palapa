defmodule ElixirTesting.Mixfile do
  use Mix.Project

  def project do
    [app: :simpler,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    # Policy dependencies: stuff that isn't required but we
    # want to be always available in stuff using Simpler.
    [{:credo, "~> 0.7", only: [:dev, :test]},
     {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
     {:excoveralls, "~> 0.6", only: :test}]
    # No other dependencies - that's a bit of a design goal for now
  end
end
