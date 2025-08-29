defmodule SensorProcessor do
  @moduledoc """
  Elixir interface to the Rust sensor processing NIFs.
  Provides functions for calling Rust-based sensor data processing.
  """

  use Rustler, otp_app: :drone_coordinator, crate: "sensor_processor", path: "../../native/sensor_processor"

  # NIF functions - these will be replaced by the actual Rust implementations
  def process_visual_data(_raw_data), do: :erlang.nif_error(:nif_not_loaded)
  def process_audio_data(_raw_data), do: :erlang.nif_error(:nif_not_loaded)
  def process_radar_data(_raw_data), do: :erlang.nif_error(:nif_not_loaded)
  def process_lidar_data(_raw_data), do: :erlang.nif_error(:nif_not_loaded)
  def calculate_flocking_forces(_drone_state, _neighbors, _params), do: :erlang.nif_error(:nif_not_loaded)
  def generate_mock_sensor_data(_drone_id, _noise_level), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Processes visual spectrum data using Rust implementation.
  Returns processed visual data including RGB, infrared, UV, and detected objects.
  """
  def process_visual(raw_data) when is_binary(raw_data) do
    raw_bytes = :binary.bin_to_list(raw_data)
    process_visual_data(raw_bytes)
  end

  @doc """
  Processes audio spectrum data using Rust implementation.
  Returns processed audio data including frequency analysis and sound detection.
  """
  def process_audio(raw_data) when is_list(raw_data) do
    process_audio_data(raw_data)
  end

  @doc """
  Processes radar readings using Rust implementation.
  Returns processed radar data including range and velocity measurements.
  """
  def process_radar(raw_data) when is_list(raw_data) do
    process_radar_data(raw_data)
  end

  @doc """
  Processes LiDAR point cloud using Rust implementation.
  Returns processed LiDAR data including filtered points and obstacle detection.
  """
  def process_lidar(point_cloud) when is_list(point_cloud) do
    process_lidar_data(point_cloud)
  end

  @doc """
  Calculates flocking forces using Rust implementation.
  Returns the calculated force vector for the given drone and neighbors.
  """
  def calculate_forces(drone_state, neighbors, params) do
    # Convert Elixir structs to maps for Rust processing
    rust_drone_state = %{
      id: drone_state.id,
      position: %{
        x: elem(drone_state.position, 0),
        y: elem(drone_state.position, 1),
        z: elem(drone_state.position, 2)
      },
      velocity: %{
        vx: elem(drone_state.velocity, 0),
        vy: elem(drone_state.velocity, 1),
        vz: elem(drone_state.velocity, 2)
      },
      timestamp: drone_state.last_update
    }

    rust_neighbors = Enum.map(neighbors, fn neighbor ->
      %{
        id: neighbor.id,
        position: %{
          x: elem(neighbor.position, 0),
          y: elem(neighbor.position, 1),
          z: elem(neighbor.position, 2)
        },
        velocity: %{
          vx: elem(neighbor.velocity, 0),
          vy: elem(neighbor.velocity, 1),
          vz: elem(neighbor.velocity, 2)
        },
        timestamp: neighbor.last_update
      }
    end)

    calculate_flocking_forces(rust_drone_state, rust_neighbors, params)
  end

  @doc """
  Generates mock sensor data using Rust implementation.
  Returns comprehensive sensor data for testing and simulation.
  """
  def generate_mock_data(drone_id, noise_level \\ 0.1) do
    generate_mock_sensor_data(drone_id, noise_level)
  end
end
