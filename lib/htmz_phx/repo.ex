defmodule HtmzPhx.Repo do
  use Ecto.Repo,
    otp_app: :htmz_phx,
    adapter: Ecto.Adapters.SQLite3
end
