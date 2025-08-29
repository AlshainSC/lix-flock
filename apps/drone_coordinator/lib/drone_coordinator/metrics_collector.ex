defmodule DroneCoordinator.MetricsCollector do
  @moduledoc """
  GenServer that collects and aggregates metrics from the drone swarm.
  Provides real-time performance data for the web interface.
  """

  use GenServer
  require Logger

  alias DroneCoordinator.{SwarmSupervisor, Drone}

  defstruct [
    :metrics_history,
    :collection_interval,
    :max_history_size
  ]

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_current_metrics do
    GenServer.call(__MODULE__, :get_current_metrics)
  end

  def get_metrics_history(duration_ms \\ 60_000) do
    GenServer.call(__MODULE__, {:get_metrics_history, duration_ms})
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      metrics_history: [],
      collection_interval: 1000,  # 1 second
      max_history_size: 300       # 5 minutes at 1s intervals
    }

    # Start periodic collection
    schedule_collection()

    {:ok, state}
  end

  @impl true
  def handle_call(:get_current_metrics, _from, state) do
    metrics = collect_current_metrics()
    {:reply, metrics, state}
  end

  @impl true
  def handle_call({:get_metrics_history, duration_ms}, _from, state) do
    cutoff_time = System.monotonic_time(:millisecond) - duration_ms
    
    filtered_history = 
      state.metrics_history
      |> Enum.filter(fn {timestamp, _} -> timestamp >= cutoff_time end)
      |> Enum.map(fn {_, metrics} -> metrics end)
    
    {:reply, filtered_history, state}
  end

  @impl true
  def handle_info(:collect_metrics, state) do
    timestamp = System.monotonic_time(:millisecond)
    metrics = collect_current_metrics()
    
    # Add to history
    new_entry = {timestamp, metrics}
    updated_history = [new_entry | state.metrics_history]
    
    # Trim history if needed
    trimmed_history = 
      if length(updated_history) > state.max_history_size do
        Enum.take(updated_history, state.max_history_size)
      else
        updated_history
      end
    
    new_state = %{state | metrics_history: trimmed_history}
    
    # Schedule next collection
    schedule_collection()
    
    {:noreply, new_state}
  end

  ## Private Functions

  defp collect_current_metrics do
    drone_ids = SwarmSupervisor.list_drones()
    drone_count = length(drone_ids)
    
    # Collect drone states
    drone_states = 
      drone_ids
      |> Enum.map(&get_drone_state_safe/1)
      |> Enum.filter(& &1)
    
    # Calculate aggregate metrics
    positions = Enum.map(drone_states, & &1.position)
    velocities = Enum.map(drone_states, & &1.velocity)
    
    %{
      timestamp: System.monotonic_time(:millisecond),
      drone_count: drone_count,
      active_drones: length(drone_states),
      swarm_center: calculate_center_of_mass(positions),
      average_velocity: calculate_average_velocity(velocities),
      swarm_spread: calculate_swarm_spread(positions),
      system_load: get_system_metrics(),
      latency_metrics: calculate_latency_metrics(drone_states)
    }
  end

  defp get_drone_state_safe(drone_id) do
    try do
      Drone.get_state(drone_id)
    catch
      :exit, _ -> nil
    end
  end

  defp calculate_center_of_mass(positions) when length(positions) > 0 do
    {sum_x, sum_y, sum_z} = 
      positions
      |> Enum.reduce({0.0, 0.0, 0.0}, fn {x, y, z}, {acc_x, acc_y, acc_z} ->
        {acc_x + x, acc_y + y, acc_z + z}
      end)
    
    count = length(positions)
    {sum_x / count, sum_y / count, sum_z / count}
  end
  defp calculate_center_of_mass(_), do: {0.0, 0.0, 0.0}

  defp calculate_average_velocity(velocities) when length(velocities) > 0 do
    {sum_vx, sum_vy, sum_vz} = 
      velocities
      |> Enum.reduce({0.0, 0.0, 0.0}, fn {vx, vy, vz}, {acc_vx, acc_vy, acc_vz} ->
        {acc_vx + vx, acc_vy + vy, acc_vz + vz}
      end)
    
    count = length(velocities)
    avg_velocity = {sum_vx / count, sum_vy / count, sum_vz / count}
    
    # Calculate magnitude
    {vx, vy, vz} = avg_velocity
    magnitude = :math.sqrt(vx * vx + vy * vy + vz * vz)
    
    %{
      vector: avg_velocity,
      magnitude: magnitude
    }
  end
  defp calculate_average_velocity(_), do: %{vector: {0.0, 0.0, 0.0}, magnitude: 0.0}

  defp calculate_swarm_spread(positions) when length(positions) > 1 do
    center = calculate_center_of_mass(positions)
    
    distances = 
      positions
      |> Enum.map(fn pos -> distance(pos, center) end)
    
    %{
      max_distance: Enum.max(distances),
      avg_distance: Enum.sum(distances) / length(distances),
      std_deviation: calculate_std_deviation(distances)
    }
  end
  defp calculate_swarm_spread(_), do: %{max_distance: 0.0, avg_distance: 0.0, std_deviation: 0.0}

  defp calculate_std_deviation(values) when length(values) > 1 do
    mean = Enum.sum(values) / length(values)
    
    variance = 
      values
      |> Enum.map(fn x -> (x - mean) * (x - mean) end)
      |> Enum.sum()
      |> Kernel./(length(values))
    
    :math.sqrt(variance)
  end
  defp calculate_std_deviation(_), do: 0.0

  defp get_system_metrics do
    memory_info = :erlang.memory()
    
    %{
      total_memory: memory_info[:total],
      process_memory: memory_info[:processes],
      system_memory: memory_info[:system],
      process_count: :erlang.system_info(:process_count),
      run_queue: :erlang.statistics(:run_queue)
    }
  end

  defp calculate_latency_metrics(drone_states) do
    current_time = System.monotonic_time(:millisecond)
    
    update_delays = 
      drone_states
      |> Enum.map(fn state -> current_time - state.last_update end)
      |> Enum.filter(fn delay -> delay >= 0 end)
    
    if length(update_delays) > 0 do
      %{
        avg_update_delay: Enum.sum(update_delays) / length(update_delays),
        max_update_delay: Enum.max(update_delays),
        min_update_delay: Enum.min(update_delays)
      }
    else
      %{
        avg_update_delay: 0.0,
        max_update_delay: 0.0,
        min_update_delay: 0.0
      }
    end
  end

  defp distance({x1, y1, z1}, {x2, y2, z2}) do
    dx = x2 - x1
    dy = y2 - y1
    dz = z2 - z1
    :math.sqrt(dx * dx + dy * dy + dz * dz)
  end

  defp schedule_collection do
    Process.send_after(self(), :collect_metrics, 1000)
  end
end
