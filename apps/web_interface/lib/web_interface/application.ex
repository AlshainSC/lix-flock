defmodule WebInterface.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Telemetry supervisor
      WebInterface.Telemetry,
      
      # Phoenix PubSub
      {Phoenix.PubSub, name: WebInterface.PubSub},
      
      # Phoenix Endpoint
      WebInterface.Endpoint,
      
      # Real-time data broadcaster
      WebInterface.DataBroadcaster
    ]

    opts = [strategy: :one_for_one, name: WebInterface.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WebInterface.Endpoint.config_change(changed, removed)
    :ok
  end
end
