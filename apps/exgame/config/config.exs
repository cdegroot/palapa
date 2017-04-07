use Mix.Config

# Import per-app configuration
import_config "../apps/*/config/config.exs"

# Import top-level configuration
import_config "#{Mix.env}.exs"
