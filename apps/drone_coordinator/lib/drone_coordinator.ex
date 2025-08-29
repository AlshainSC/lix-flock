defmodule DroneCoordinator do
  @moduledoc """
  Main API module for the DroneCoordinator application.
  Provides high-level functions for managing the drone swarm.
  """

  alias DroneCoordinator.{SwarmSupervisor, FlockingCoordinator, MetricsCollector}

  ## Public API

  @doc """
  Spawns a new drone with optional configuration.
  """
  def spawn_drone(opts \\ []) do
    SwarmSupervisor.spawn_drone(opts)
  end

  @doc """
  Spawns multiple drones to form a swarm.
  """
  def spawn_swarm(count) do
    SwarmSupervisor.spawn_swarm(count)
  end

  @doc """
  Terminates a specific drone.
  """
  def terminate_drone(drone_id) do
    SwarmSupervisor.terminate_drone(drone_id)
  end

  @doc """
  Lists all active drones.
  """
  def list_drones do
    SwarmSupervisor.list_drones()
  end

  @doc """
  Gets the current drone count.
  """
  def drone_count do
    SwarmSupervisor.drone_count()
  end

  @doc """
  Updates flocking parameters.
  """
  def update_flocking_parameters(params) do
    FlockingCoordinator.update_parameters(params)
  end

  @doc """
  Gets current flocking parameters.
  """
  def get_flocking_parameters do
    FlockingCoordinator.get_parameters()
  end

  @doc """
  Gets current swarm metrics.
  """
  def get_metrics do
    MetricsCollector.get_current_metrics()
  end

  @doc """
  Gets metrics history for the specified duration.
  """
  def get_metrics_history(duration_ms \\ 60_000) do
    MetricsCollector.get_metrics_history(duration_ms)
  end

  @doc """
  Gets a specific drone by ID.
  """
  def get_drone(drone_id) do
    SwarmSupervisor.get_drone(drone_id)
  end

  @doc """
  Lists all drones with their current positions.
  """
  def list_drones_with_positions do
    SwarmSupervisor.list_drones_with_positions()
  end

  @doc """
  Terminates all active drones.
  """
  def terminate_all_drones do
    SwarmSupervisor.terminate_all_drones()
  end

  # Legacy function aliases for backward compatibility
  def get_flocking_params, do: get_flocking_parameters()
  def update_flocking_params(params), do: update_flocking_parameters(params)
end
