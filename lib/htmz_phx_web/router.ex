defmodule HtmzPhxWeb.Router do
  use HtmzPhxWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HtmzPhxWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug HtmzPhxWeb.Auth.JWTPlug
  end

  pipeline :api do
    plug :accepts, ["json", "html"]
    plug :fetch_session
    plug HtmzPhxWeb.Auth.JWTPlug
  end

  scope "/", HtmzPhxWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/cart", PageController, :cart
    get "/item/:id", PageController, :item_details
    get "/cart-count", PageController, :cart_count
    get "/cart-total", PageController, :cart_total
    get "/presence", PageController, :presence
  end

  scope "/api", HtmzPhxWeb do
    pipe_through :api

    post "/cart/add/:item_id", CartController, :add
    delete "/cart/remove/:item_id", CartController, :remove
    post "/cart/increase-quantity/:item_id", CartController, :increase_quantity
    post "/cart/decrease-quantity/:item_id", CartController, :decrease_quantity
    get "/items", CartController, :get_items
    get "/item-details/:item_id", PageController, :item_details_fragment
    post "/cleanup-carts", CartController, :cleanup_carts
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:htmz_phx, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HtmzPhxWeb.Telemetry
    end
  end
end
