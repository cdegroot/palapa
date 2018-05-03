defmodule Amnesix.Mixfile do
  use Mix.Project

  def project do
    [app: :amnesix,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     deps: deps(),
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [extra_applications: [:logger, :brod],
     mod: {Amnesix.Application, []}]
  end

  defp deps do
    [{:brod, "~> 2.2"},
     {:simpler, in_umbrella: true}]
  end
end
