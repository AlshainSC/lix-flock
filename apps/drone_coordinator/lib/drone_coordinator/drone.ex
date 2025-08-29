defmodule DroneCoordinator.Drone do
  @moduledoc """
  GenServer representing a single drone in the swarm.
  Manages drone state, position, velocity, and sensor data.
  """

  use GenServer
  require Logger

  alias DroneCoordinator.{SensorDataManager, FlockingCoordinator}

  defstruct [
    :id,
    :position,      # {x, y, z}
    :velocity,      # {vx, vy, vz}
    :acceleration,  # {ax, ay, az}
    :sensors,       # Map of sensor readings
    :neighbors,     # List of nearby drone IDs
    :last_update,   # Timestamp
    :status         # :active, :inactive, :error
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    position: {float(), float(), float()},
    velocity: {float(), float(), float()},
    acceleration: {float(), float(), float()},
    sensors: map(),
    neighbors: [String.t()],
    last_update: integer(),
    status: :active | :inactive | :error
  }

  ## Client API

  def start_link(opts) do
    {id, opts} = Keyword.pop(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(id))
  end

  def get_state(drone_id) do
    GenServer.call(via_tuple(drone_id), :get_state)
  end

  def update_position(drone_id, position) do
    GenServer.cast(via_tuple(drone_id), {:update_position, position})
  end

  def update_velocity(drone_id, velocity) do
    GenServer.cast(via_tuple(drone_id), {:update_velocity, velocity})
  end

  def update_sensors(drone_id, sensor_data) do
    GenServer.cast(via_tuple(drone_id), {:update_sensors, sensor_data})
  end

  def set_neighbors(drone_id, neighbors) do
    GenServer.cast(via_tuple(drone_id), {:set_neighbors, neighbors})
  end

  ## Server Callbacks

  @impl true
  def init(opts) do
    id = Keyword.get(opts, :id, generate_id())
    initial_position = Keyword.get(opts, :position, random_position())
    initial_velocity = Keyword.get(opts, :velocity, {0.0, 0.0, 0.0})

    state = %__MODULE__{
      id: id,
      position: initial_position,
      velocity: initial_velocity,
      acceleration: {0.0, 0.0, 0.0},
      sensors: %{},
      neighbors: [],
      last_update: System.monotonic_time(:millisecond),
      status: :active
    }

    # Schedule periodic updates
    schedule_update()

    Logger.info("Drone #{id} initialized at position #{inspect(initial_position)}")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:update_position, position}, state) do
    new_state = %{state | 
      position: position, 
      last_update: System.monotonic_time(:millisecond)
    }
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_velocity, velocity}, state) do
    new_state = %{state | 
      velocity: velocity, 
      last_update: System.monotonic_time(:millisecond)
    }
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_sensors, sensor_data}, state) do
    new_state = %{state | 
      sensors: Map.merge(state.sensors, sensor_data),
      last_update: System.monotonic_time(:millisecond)
    }
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:set_neighbors, neighbors}, state) do
    new_state = %{state | neighbors: neighbors}
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:update, state) do
    # Request sensor data update
    SensorDataManager.request_sensor_data(state.id)
    
    # Request flocking calculation
    FlockingCoordinator.calculate_flocking_forces(state.id, state)
    
    # Schedule next update
    schedule_update()
    
    {:noreply, state}
  end

  ## Private Functions

  defp via_tuple(drone_id) do
    {:via, Registry, {DroneCoordinator.DroneRegistry, drone_id}}
  end

  defp generate_id do
    "drone_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp random_position do
    {x_bound, y_bound, z_bound} = Application.get_env(:drone_coordinator, :world_bounds, {1000, 1000, 500})
    
    {
      :rand.uniform() * x_bound - x_bound / 2,
      :rand.uniform() * y_bound - y_bound / 2,
      :rand.uniform() * z_bound
    }
  end

  defp schedule_update do
    Process.send_after(self(), :update, 16)  # ~60 FPS
  end
end
