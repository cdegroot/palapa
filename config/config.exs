# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.env == :dev do

config :mix_test_watch,
  clear: true,
  tasks: ["test", "credo --strict"]

end

import_config "../apps/*/config/config.exs"

# Umbrella-wide overrised

if Mix.env == :test do

  config :logger, level: :debug

end
