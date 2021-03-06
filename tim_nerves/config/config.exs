# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Customize non-Elixir parts of the firmware.  See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.
config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]

config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
  ]

config :nerves_init_gadget,
  ifname: "eth0",
  address_method: :dhcp,
  node_name: "tim",
  ssh_console_port: 22

config :clixir, application: :tim_uderzo_ui

config :logger, level: :error
config :logger, RingLogger, max_size: 100

config :tzdata, :autoupdate, :disabled

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations
import_config "#{Mix.Project.config[:target]}.exs"
