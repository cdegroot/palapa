defmodule Palapa.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     test_paths: test_paths(),
     preferred_cli_env: [
       "coveralls": :test,
       "coveralls.detail": :test,
       "coveralls.post": :test,
       "coveralls.html": :test,
       "test_all": :test],
     deps: deps()]
  end

  # See https://groups.google.com/forum/#!topic/elixir-lang-core/8wX8i5sEtFg
  def test_paths do
    "apps/*/test" |> Path.wildcard |> Enum.sort
  end

  defp deps do
    [{:excoveralls, "~> 0.6", only: :test},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
     {:mix_test_watch, "~> 0.3", only: :dev}]
  end
end

# `mix test` cd's into each app directory in sequence and runs the tests.
# `mix test_all` runs tests for all apps at the same time.
defmodule Mix.Tasks.TestAll do
  use Mix.Task
  @shortdoc "Runs all tests in parallel"
  defdelegate run(args), to: Mix.Tasks.Test
end

