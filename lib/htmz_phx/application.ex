defmodule HtmzPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    HtmzPhx.Release.migrate()

    children = [
      HtmzPhxWeb.Telemetry,
      HtmzPhx.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:htmz_phx, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:htmz_phx, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HtmzPhx.PubSub},
      HtmzPhx.Presence,
      HtmzPhx.CartManager,
      HtmzPhxWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: HtmzPhx.Supervisor]
    result = Supervisor.start_link(children, opts)

    Task.start(fn ->
      # # Wait for repo to be ready
      # :timer.sleep(1000)

      if HtmzPhx.GroceryItems.get_all_items() |> length() == 0 do
        HtmzPhx.GroceryItems.create_items()
      end
    end)

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HtmzPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
