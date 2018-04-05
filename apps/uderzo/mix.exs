defmodule Mix.Tasks.Compile.Native do
  def run(_) do
    case :os.type do
      {_, :linux} ->
        {result, _error_code} = System.cmd("make", ["-f", "Makefile.linux", "compile"], stderr_to_stdout: true)
        IO.binwrite(result)
      _ ->
        IO.warn("Operating system not yet supported")
        exit(1)
    end
    :ok
  end
end

defmodule Uderzo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :uderzo,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      compilers: [:native | Mix.compilers ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
    ]
  end
end
