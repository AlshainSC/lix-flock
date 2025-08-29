defmodule DroneCoordinator.Telemetry do
  @moduledoc """
  Telemetry setup for monitoring drone coordinator performance.
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Drone metrics
      counter("drone_coordinator.drone.spawned.count"),
      counter("drone_coordinator.drone.terminated.count"),
      last_value("drone_coordinator.swarm.active_count"),
      
      # Flocking metrics
      summary("drone_coordinator.flocking.calculation_time",
        unit: {:native, :millisecond}
      ),
      counter("drone_coordinator.flocking.calculations.count"),
      
      # Sensor metrics
      counter("drone_coordinator.sensors.requests.count"),
      summary("drone_coordinator.sensors.processing_time",
        unit: {:native, :millisecond}
      ),
      
      # System metrics
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      {DroneCoordinator.SwarmSupervisor, :telemetry_drone_count, []}
    ]
  end
end
