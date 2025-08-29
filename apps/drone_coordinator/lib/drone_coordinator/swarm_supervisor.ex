defmodule DroneCoordinator.SwarmSupervisor do
  @moduledoc """
  DynamicSupervisor that manages drone processes.
  Allows for dynamic addition and removal of drones during runtime.
  """

  use DynamicSupervisor
  require Logger

  alias DroneCoordinator.Drone

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def spawn_drone(opts \\ []) do
    drone_spec = {Drone, opts}
    
    case DynamicSupervisor.start_child(__MODULE__, drone_spec) do
      {:ok, pid} ->
        drone_id = Keyword.get(opts, :id, get_drone_id(pid))
        Logger.info("Spawned drone #{drone_id}")
        {:ok, pid, drone_id}
      
      {:error, reason} ->
        Logger.error("Failed to spawn drone: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def terminate_drone(drone_id) do
    case Registry.lookup(DroneCoordinator.DroneRegistry, drone_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        Logger.info("Terminated drone #{drone_id}")
        :ok
      
      [] ->
        Logger.warning("Drone #{drone_id} not found")
        {:error, :not_found}
    end
  end

  def list_drones do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> get_drone_id(pid) end)
    |> Enum.filter(& &1)
  end

  def drone_count do
    DynamicSupervisor.count_children(__MODULE__).active
  end

  def spawn_swarm(count) when count > 0 do
    max_drones = Application.get_env(:drone_coordinator, :max_drones, 50)
    current_count = drone_count()
    
    spawn_count = min(count, max_drones - current_count)
    
    if spawn_count > 0 do
      results = 
        1..spawn_count
        |> Enum.map(fn _ -> spawn_drone() end)
        |> Enum.filter(fn {status, _, _} -> status == :ok end)
      
      Logger.info("Spawned #{length(results)} drones (requested: #{count})")
      {:ok, length(results)}
    else
      Logger.warning("Cannot spawn drones: limit reached (#{current_count}/#{max_drones})")
      {:error, :limit_reached}
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp get_drone_id(pid) do
    try do
      Drone.get_state(pid).id
    catch
      :exit, _ -> nil
    end
  end

  def get_drone(drone_id) do
    case Registry.lookup(DroneCoordinator.DroneRegistry, drone_id) do
      [{pid, _}] ->
        try do
          {:ok, Drone.get_state(pid)}
        catch
          :exit, _ -> {:error, :not_found}
        end
      
      [] ->
        {:error, :not_found}
    end
  end

  def list_drones_with_positions do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      try do
        state = Drone.get_state(pid)
        %{
          id: state.id,
          position: state.position,
          velocity: state.velocity,
          status: :active
        }
      catch
        :exit, _ -> nil
      end
    end)
    |> Enum.filter(& &1)
  end

  def terminate_all_drones do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.each(fn {_, pid, _, _} ->
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end)
    
    Logger.info("Terminated all drones")
    :ok
  end

  # Telemetry measurement function
  def telemetry_drone_count do
    try do
      drone_count()
    catch
      :exit, _ -> 0
    end
  end
end
