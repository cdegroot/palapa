# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :ui, UiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qnfGtBhwJQN4RhfU98CBUQtcuR4OqVLyq6C0YO8+GmAZOdM07G10En38I9a3oyJf",
  render_errors: [view: UiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ui.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "ogei9lwLAcU9hc4SHfXHdrO2PCW0MU0I"
  ]

# Configures Elixir's Logger
if Mix.target() == :host do
  config :logger, :console,
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id]
else
  config :logger,
    backends: [RingLogger]
end

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :firmware, target: Mix.target()

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]

config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
  ]

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

import_config "#{Mix.env()}.exs"

if Mix.target() != :host do
  import_config "target.exs"
end
