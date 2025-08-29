defmodule DroneCoordinator.Application do
  @moduledoc """
  The DroneCoordinator Application manages the supervision tree for drone processes
  and coordinates the overall swarm behavior.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Telemetry supervisor
      DroneCoordinator.Telemetry,
      
      # Drone registry - process registration for drones
      {Registry, keys: :unique, name: DroneCoordinator.DroneRegistry},
      
      # Swarm supervisor - manages individual drone processes
      {DroneCoordinator.SwarmSupervisor, []},
      
      # Flocking coordinator - manages swarm-wide behavior
      {DroneCoordinator.FlockingCoordinator, []},
      
      # Sensor data manager - handles sensor data distribution
      {DroneCoordinator.SensorDataManager, []},
      
      # Metrics collector
      {DroneCoordinator.MetricsCollector, []}
    ]

    opts = [strategy: :one_for_one, name: DroneCoordinator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
