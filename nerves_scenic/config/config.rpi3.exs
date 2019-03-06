use Mix.Config

config :nerves_scenic, :viewport, %{
  name: :main_viewport,
  # default_scene: {NervesScenic.Scene.Crosshair, nil},
  default_scene: {NervesScenic.Scene.SysInfo, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
    %{
      module: Scenic.Driver.Nerves.Touch,
      opts: [
        device: "FT5406 memory based driver",
        calibration: {{1, 0, 0}, {1, 0, 0}}
      ]
    }
  ]
}
