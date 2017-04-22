# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

import_config "../apps/*/config/config.exs"

# Umbrella-wide overrides

if Mix.env == :dev do

config :mix_test_watch,
  clear: true,
  exclude: [
    ~r/\.#/],
  tasks: ["test"]

end

if Mix.env == :test do

  config :logger, level: :error

end
