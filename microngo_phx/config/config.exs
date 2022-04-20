# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :microngo_phx, ecto_repos: [MicrongoPhx.Repo]

# Configures the endpoint
config :microngo_phx, MicrongoPhxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OOvyisL0YXZCnI+bRihJtqoR42514uaWPbSsQjxMEZF+i7d7NutmRqCdXL4z5qG7",
  render_errors: [view: MicrongoPhxWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MicrongoPhx.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :microngo_phx, MicrongoPhxWeb.Gettext, default_locale: "en", locales: ~w(en ko)
