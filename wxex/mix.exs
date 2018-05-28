defmodule Wxex.Mixfile do
  use Mix.Project

  def project do
    [app: :wxex,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :wx]]
  end

  defp deps do
    []
  end
end
