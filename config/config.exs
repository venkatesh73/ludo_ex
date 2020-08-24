# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :ludo_ex,
  ecto_repos: [LudoEx.Repo]

# Configures the endpoint
config :ludo_ex, LudoExWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "o/mk194R1LIpyZLlLICvoXbR8i4nzf3EO5JSIcF6g0u08VlCYMChyQx61+3AqP4h",
  render_errors: [view: LudoExWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LudoEx.PubSub,
  live_view: [signing_salt: "2tnGoI0e"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
