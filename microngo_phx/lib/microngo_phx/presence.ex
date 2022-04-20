defmodule MicrongoPhx.Presence do
  use Phoenix.Presence,
    otp_app: :microngo_phx,
    pubsub_server: MicrongoPhx.PubSub
end
