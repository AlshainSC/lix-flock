defmodule DroneCoordinator.SensorDataManager do
  @moduledoc """
  GenServer that manages sensor data requests and distribution.
  Interfaces with Rust sensor processing modules via NIFs.
  """

  use GenServer
  require Logger

  alias DroneCoordinator.Drone

  defstruct [
    :sensor_frequency,
    :active_requests,
    :sensor_cache
  ]

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def request_sensor_data(drone_id) do
    GenServer.cast(__MODULE__, {:request_sensor_data, drone_id})
  end

  def get_sensor_data(drone_id, sensor_type) do
    GenServer.call(__MODULE__, {:get_sensor_data, drone_id, sensor_type})
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    frequency = Application.get_env(:sensor_processor, :update_frequency, 60)
    
    state = %__MODULE__{
      sensor_frequency: frequency,
      active_requests: MapSet.new(),
      sensor_cache: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get_sensor_data, drone_id, sensor_type}, _from, state) do
    data = get_from_cache(state.sensor_cache, drone_id, sensor_type)
    {:reply, data, state}
  end

  @impl true
  def handle_cast({:request_sensor_data, drone_id}, state) do
    # Avoid duplicate requests
    if not MapSet.member?(state.active_requests, drone_id) do
      new_requests = MapSet.put(state.active_requests, drone_id)
      
      # Generate mock sensor data (will be replaced with Rust NIF calls)
      sensor_data = generate_mock_sensor_data(drone_id)
      
      # Update drone with sensor data
      Drone.update_sensors(drone_id, sensor_data)
      
      # Cache the data
      new_cache = cache_sensor_data(state.sensor_cache, drone_id, sensor_data)
      
      # Remove from active requests
      final_requests = MapSet.delete(new_requests, drone_id)
      
      new_state = %{state | 
        active_requests: final_requests,
        sensor_cache: new_cache
      }
      
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  ## Private Functions

  defp generate_mock_sensor_data(drone_id) do
    noise_level = Application.get_env(:sensor_processor, :sensor_noise, 0.1)
    timestamp = System.monotonic_time(:millisecond)
    
    %{
      visual: generate_visual_data(noise_level),
      audio: generate_audio_data(noise_level),
      radar: generate_radar_data(noise_level),
      lidar: generate_lidar_data(noise_level),
      timestamp: timestamp,
      drone_id: drone_id
    }
  end

  defp generate_visual_data(noise) do
    %{
      rgb: {
        add_noise(128, noise),
        add_noise(128, noise),
        add_noise(128, noise)
      },
      infrared: add_noise(50, noise),
      uv: add_noise(30, noise),
      brightness: add_noise(0.5, noise),
      contrast: add_noise(0.5, noise),
      detected_objects: []
    }
  end

  defp generate_audio_data(noise) do
    %{
      amplitude: add_noise(0.3, noise),
      frequency_spectrum: Enum.map(1..10, fn _ -> add_noise(0.1, noise) end),
      direction: add_noise(0.0, noise),  # Radians
      detected_sounds: []
    }
  end

  defp generate_radar_data(noise) do
    %{
      range_readings: Enum.map(1..8, fn _ -> add_noise(100.0, noise * 10) end),
      velocity_readings: Enum.map(1..8, fn _ -> add_noise(0.0, noise) end),
      detected_objects: []
    }
  end

  defp generate_lidar_data(noise) do
    # Generate a simplified point cloud
    points = for i <- 1..36, j <- 1..10 do
      angle = i * 10 * :math.pi() / 180  # 10-degree increments
      elevation = (j - 5) * 5 * :math.pi() / 180  # -20 to +25 degrees
      distance = add_noise(50.0, noise * 5)
      
      x = distance * :math.cos(elevation) * :math.cos(angle)
      y = distance * :math.cos(elevation) * :math.sin(angle)
      z = distance * :math.sin(elevation)
      
      {x, y, z}
    end
    
    %{
      point_cloud: points,
      intensity: Enum.map(points, fn _ -> add_noise(0.8, noise) end),
      detected_obstacles: []
    }
  end

  defp add_noise(base_value, noise_level) when is_number(base_value) do
    noise = ((:rand.uniform() - 0.5) * 2) * noise_level * base_value
    base_value + noise
  end

  defp cache_sensor_data(cache, drone_id, sensor_data) do
    Map.put(cache, drone_id, sensor_data)
  end

  defp get_from_cache(cache, drone_id, sensor_type) do
    case Map.get(cache, drone_id) do
      nil -> nil
      data -> Map.get(data, sensor_type)
    end
  end
end
