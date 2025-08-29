defmodule WebInterface.Router do
  use WebInterface, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WebInterface.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebInterface do
    pipe_through :browser

    live "/", DashboardLive, :index
    live "/swarm", SwarmLive, :index
    live "/metrics", MetricsLive, :index
    live "/controls", ControlsLive, :index
  end

  scope "/api", WebInterface do
    pipe_through :api

    get "/drones", DroneController, :index
    post "/drones", DroneController, :create
    delete "/drones/:id", DroneController, :delete
    get "/metrics", MetricsController, :index
    put "/flocking", FlockingController, :update
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:web_interface, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WebInterface.Telemetry
    end
  end
end
