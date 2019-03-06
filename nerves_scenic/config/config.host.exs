use Mix.Config

config :nerves_scenic, :viewport, %{
  name: :main_viewport,
  # default_scene: {NervesScenic.Scene.Crosshair, nil},
  default_scene: {NervesScenic.Scene.SysInfo, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :nerves_scenic"]
    }
  ]
}
