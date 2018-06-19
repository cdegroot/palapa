defmodule TimNerves.MixProject do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  def project do
    [
      app: :tim_nerves,
      version: "0.1.0",
      elixir: "~> 1.4",
      target: @target,
      archives: [nerves_bootstrap: "~> 1.0"],
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      start_permanent: Mix.env() == :prod,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps()
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {TimNerves.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nerves, "~> 1.0", runtime: false},
      {:tim_uderzo_ui, path: "../tim_uderzo_ui"},
      {:shoehorn, "~> 0.2"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  defp deps("host"), do: []

  defp deps(target) do
    [
      {:nerves_runtime, "~> 0.4"}
    ] ++ system(target)
  end

  defp system("rpi3"), do: [{:nerves_system_rpi3_tftfb, "~> 1.0 or ~> 1.0-rc", runtime: false}]
  defp system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")
end
