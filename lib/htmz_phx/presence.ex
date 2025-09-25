defmodule HtmzPhx.Presence do
  use Phoenix.Presence,
    otp_app: :htmz_phx,
    pubsub_server: HtmzPhx.PubSub
end