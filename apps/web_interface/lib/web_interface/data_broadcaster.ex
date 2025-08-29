defmodule WebInterface.DataBroadcaster do
  @moduledoc """
  GenServer that broadcasts real-time drone data to connected web clients.
  """

  use GenServer
  require Logger

  alias DroneCoordinator

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule periodic broadcasts
    :timer.send_interval(100, self(), :broadcast_drone_positions)  # 10 FPS
    :timer.send_interval(1000, self(), :broadcast_metrics)         # 1 Hz

    {:ok, %{}}
  end

  @impl true
  def handle_info(:broadcast_drone_positions, state) do
    drone_ids = DroneCoordinator.list_drones()
    
    drone_positions = 
      drone_ids
      |> Enum.map(&get_drone_position/1)
      |> Enum.filter(& &1)

    if length(drone_positions) > 0 do
      Phoenix.PubSub.broadcast(
        WebInterface.PubSub,
        "swarm_positions",
        {:position_update, drone_positions}
      )
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:broadcast_metrics, state) do
    metrics = DroneCoordinator.get_metrics()
    
    Phoenix.PubSub.broadcast(
      WebInterface.PubSub,
      "swarm_metrics",
      {:metrics_update, metrics}
    )

    {:noreply, state}
  end

  defp get_drone_position(drone_id) do
    try do
      drone_state = DroneCoordinator.Drone.get_state(drone_id)
      %{
        id: drone_state.id,
        position: drone_state.position,
        velocity: drone_state.velocity,
        status: drone_state.status
      }
    catch
      :exit, _ -> nil
    end
  end
end
