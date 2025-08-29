defmodule DroneCoordinator.FlockingCoordinator do
  @moduledoc """
  GenServer that coordinates flocking behavior across the entire swarm.
  Implements Reynolds' boids algorithm with separation, alignment, and cohesion.
  """

  use GenServer
  require Logger

  alias DroneCoordinator.{Drone, SwarmSupervisor}

  defstruct [
    :neighbor_radius,
    :separation_radius,
    :max_speed,
    :max_force,
    :separation_weight,
    :alignment_weight,
    :cohesion_weight
  ]

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def calculate_flocking_forces(drone_id, drone_state) do
    GenServer.cast(__MODULE__, {:calculate_forces, drone_id, drone_state})
  end

  def update_parameters(params) do
    GenServer.call(__MODULE__, {:update_parameters, params})
  end

  def get_parameters do
    GenServer.call(__MODULE__, :get_parameters)
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      neighbor_radius: 100.0,
      separation_radius: 50.0,
      max_speed: 50.0,
      max_force: 10.0,
      separation_weight: 2.0,
      alignment_weight: 1.0,
      cohesion_weight: 1.0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:update_parameters, params}, _from, state) do
    new_state = struct(state, params)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_parameters, _from, state) do
    params = Map.from_struct(state)
    {:reply, params, state}
  end

  @impl true
  def handle_cast({:calculate_forces, drone_id, drone_state}, state) do
    # Get all drone states for neighbor calculation
    neighbors = find_neighbors(drone_id, drone_state, state.neighbor_radius)
    
    # Calculate flocking forces
    separation_force = calculate_separation(drone_state, neighbors, state)
    alignment_force = calculate_alignment(drone_state, neighbors, state)
    cohesion_force = calculate_cohesion(drone_state, neighbors, state)
    
    # Combine forces
    total_force = combine_forces([
      {separation_force, state.separation_weight},
      {alignment_force, state.alignment_weight},
      {cohesion_force, state.cohesion_weight}
    ])
    
    # Apply force limits
    limited_force = limit_force(total_force, state.max_force)
    
    # Update drone velocity
    new_velocity = add_vectors(drone_state.velocity, limited_force)
    limited_velocity = limit_velocity(new_velocity, state.max_speed)
    
    # Update drone position
    new_position = add_vectors(drone_state.position, limited_velocity)
    bounded_position = apply_boundaries(new_position)
    
    # Send updates to drone
    Drone.update_velocity(drone_id, limited_velocity)
    Drone.update_position(drone_id, bounded_position)
    Drone.set_neighbors(drone_id, Enum.map(neighbors, & &1.id))
    
    {:noreply, state}
  end

  ## Private Functions

  defp find_neighbors(drone_id, drone_state, radius) do
    SwarmSupervisor.list_drones()
    |> Enum.reject(&(&1 == drone_id))
    |> Enum.map(&get_drone_state/1)
    |> Enum.filter(&(&1 != nil))
    |> Enum.filter(fn neighbor ->
      distance(drone_state.position, neighbor.position) <= radius
    end)
  end

  defp get_drone_state(drone_id) do
    try do
      Drone.get_state(drone_id)
    catch
      :exit, _ -> nil
    end
  end

  defp calculate_separation(drone_state, neighbors, state) do
    close_neighbors = Enum.filter(neighbors, fn neighbor ->
      distance(drone_state.position, neighbor.position) <= state.separation_radius
    end)
    
    if Enum.empty?(close_neighbors) do
      {0.0, 0.0, 0.0}
    else
      separation_sum = 
        close_neighbors
        |> Enum.map(fn neighbor ->
          diff = subtract_vectors(drone_state.position, neighbor.position)
          dist = vector_magnitude(diff)
          
          if dist > 0 do
            # Normalize and weight by inverse distance
            normalized = normalize_vector(diff)
            scale_vector(normalized, 1.0 / dist)
          else
            {0.0, 0.0, 0.0}
          end
        end)
        |> Enum.reduce({0.0, 0.0, 0.0}, &add_vectors/2)
      
      if vector_magnitude(separation_sum) > 0 do
        normalize_vector(separation_sum)
      else
        {0.0, 0.0, 0.0}
      end
    end
  end

  defp calculate_alignment(drone_state, neighbors, _state) do
    if Enum.empty?(neighbors) do
      {0.0, 0.0, 0.0}
    else
      avg_velocity = 
        neighbors
        |> Enum.map(& &1.velocity)
        |> Enum.reduce({0.0, 0.0, 0.0}, &add_vectors/2)
        |> scale_vector(1.0 / length(neighbors))
      
      desired_velocity = normalize_vector(avg_velocity)
      subtract_vectors(desired_velocity, normalize_vector(drone_state.velocity))
    end
  end

  defp calculate_cohesion(drone_state, neighbors, _state) do
    if Enum.empty?(neighbors) do
      {0.0, 0.0, 0.0}
    else
      center_of_mass = 
        neighbors
        |> Enum.map(& &1.position)
        |> Enum.reduce({0.0, 0.0, 0.0}, &add_vectors/2)
        |> scale_vector(1.0 / length(neighbors))
      
      desired_direction = subtract_vectors(center_of_mass, drone_state.position)
      
      if vector_magnitude(desired_direction) > 0 do
        normalize_vector(desired_direction)
      else
        {0.0, 0.0, 0.0}
      end
    end
  end

  defp combine_forces(weighted_forces) do
    weighted_forces
    |> Enum.map(fn {{fx, fy, fz}, weight} ->
      {fx * weight, fy * weight, fz * weight}
    end)
    |> Enum.reduce({0.0, 0.0, 0.0}, &add_vectors/2)
  end

  defp limit_force({fx, fy, fz}, max_force) do
    magnitude = :math.sqrt(fx * fx + fy * fy + fz * fz)
    
    if magnitude > max_force do
      scale = max_force / magnitude
      {fx * scale, fy * scale, fz * scale}
    else
      {fx, fy, fz}
    end
  end

  defp limit_velocity({vx, vy, vz}, max_speed) do
    magnitude = :math.sqrt(vx * vx + vy * vy + vz * vz)
    
    if magnitude > max_speed do
      scale = max_speed / magnitude
      {vx * scale, vy * scale, vz * scale}
    else
      {vx, vy, vz}
    end
  end

  defp apply_boundaries({x, y, z}) do
    {x_bound, y_bound, z_bound} = Application.get_env(:drone_coordinator, :world_bounds, {1000, 1000, 500})
    
    bounded_x = max(-x_bound/2, min(x_bound/2, x))
    bounded_y = max(-y_bound/2, min(y_bound/2, y))
    bounded_z = max(0, min(z_bound, z))
    
    {bounded_x, bounded_y, bounded_z}
  end

  # Vector math utilities
  defp distance({x1, y1, z1}, {x2, y2, z2}) do
    dx = x2 - x1
    dy = y2 - y1
    dz = z2 - z1
    :math.sqrt(dx * dx + dy * dy + dz * dz)
  end

  defp add_vectors({x1, y1, z1}, {x2, y2, z2}) do
    {x1 + x2, y1 + y2, z1 + z2}
  end

  defp subtract_vectors({x1, y1, z1}, {x2, y2, z2}) do
    {x1 - x2, y1 - y2, z1 - z2}
  end

  defp scale_vector({x, y, z}, scale) do
    {x * scale, y * scale, z * scale}
  end

  defp vector_magnitude({x, y, z}) do
    :math.sqrt(x * x + y * y + z * z)
  end

  defp normalize_vector({x, y, z}) do
    magnitude = vector_magnitude({x, y, z})
    
    if magnitude > 0 do
      {x / magnitude, y / magnitude, z / magnitude}
    else
      {0.0, 0.0, 0.0}
    end
  end
end
