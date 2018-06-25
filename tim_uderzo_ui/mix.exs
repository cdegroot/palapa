defmodule UderzoExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :tim_uderzo_ui,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      make_env: &make_env/0,
      compilers: Mix.compilers ++ [:clixir, :elixir_make]
    ]
  end

  def application do
    [
      mod: {TimUderzoUi.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp make_env() do
    erl_env = case System.get_env("ERL_EI_INCLUDE_DIR") do
                nil ->
                  %{
                    "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
                    "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib",
              }
                _ ->
                  %{}
              end
    erl_env
    |> Map.put("MIX_ENV", "#{Mix.env}")
    |> Map.put("CLIXIR_DIR", Mix.Project.build_path <> "/lib/clixir/priv")
    |> Map.put("UDERZO_DIR", Mix.Project.build_path <> "/lib/uderzo/priv")
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uderzo, "~> 0.5.1"},
      {:timex, "~> 3.3"}
    ]
  end
end
