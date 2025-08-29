defmodule WebInterface.SwarmLive do
  use WebInterface, :live_view

  alias DroneCoordinator

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebInterface.PubSub, "swarm_updates")
      :timer.send_interval(100, self(), :update_positions)
    end

    socket =
      socket
      |> assign(:drones, [])
      |> assign(:page_title, "3D Swarm View")
      |> load_drone_data()

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_positions, socket) do
    drones = DroneCoordinator.list_drones_with_positions()
    {:noreply, assign(socket, :drones, drones)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white">
      <!-- Mobile/Tablet Header -->
      <div class="bg-gray-800 shadow-lg">
        <div class="px-4 py-4">
          <div class="flex justify-between items-center">
            <h1 class="text-2xl md:text-3xl font-bold text-blue-400">Swarm View</h1>
            <div class="flex items-center space-x-4">
              <span class="px-3 py-1 bg-green-600 rounded-full text-sm font-medium">
                <%= length(@drones) %> Drones
              </span>
              <.link navigate={~p"/controls"} class="bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded text-sm font-medium">
                Controls
              </.link>
            </div>
          </div>
        </div>
      </div>

      <!-- Full Screen Canvas for Tablet -->
      <div class="p-2">
        <div class="bg-gray-800 rounded-lg overflow-hidden">
          <canvas 
            id="swarm-canvas" 
            class="w-full bg-black border-2 border-gray-600"
            style="height: calc(100vh - 200px); min-height: 600px;"
            phx-hook="DroneVisualization"
            data-drones={Jason.encode!(@drones)}
          >
          </canvas>
        </div>
      </div>

      <!-- Bottom Stats Panel for Tablet -->
      <div class="fixed bottom-0 left-0 right-0 bg-gray-800 border-t border-gray-600 p-4">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div class="bg-gray-700 rounded-lg p-3">
            <div class="text-blue-400 font-semibold text-sm">Active Drones</div>
            <div class="text-xl font-bold"><%= length(@drones) %></div>
          </div>
          <div class="bg-gray-700 rounded-lg p-3">
            <div class="text-green-400 font-semibold text-sm">Avg Speed</div>
            <div class="text-xl font-bold"><%= calculate_avg_speed(@drones) %> m/s</div>
          </div>
          <div class="bg-gray-700 rounded-lg p-3">
            <div class="text-purple-400 font-semibold text-sm">Formation</div>
            <div class="text-xl font-bold">Flocking</div>
          </div>
          <div class="bg-gray-700 rounded-lg p-3">
            <div class="text-orange-400 font-semibold text-sm">Status</div>
            <div class="text-xl font-bold text-green-400">Active</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_drone_data(socket) do
    drones = DroneCoordinator.list_drones_with_positions()
    assign(socket, :drones, drones)
  end

  defp calculate_avg_speed(drones) do
    if length(drones) > 0 do
      total_speed = Enum.reduce(drones, 0, fn drone, acc ->
        speed = if drone.velocity do
          :math.sqrt(
            :math.pow(drone.velocity.x, 2) +
            :math.pow(drone.velocity.y, 2) +
            :math.pow(drone.velocity.z, 2)
          )
        else
          0
        end
        acc + speed
      end)
      Float.round(total_speed / length(drones), 1)
    else
      0.0
    end
  end
end
