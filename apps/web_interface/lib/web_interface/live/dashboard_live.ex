defmodule WebInterface.DashboardLive do
  use WebInterface, :live_view

  alias DroneCoordinator

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebInterface.PubSub, "swarm_updates")
      :timer.send_interval(1000, self(), :update_metrics)
    end

    socket =
      socket
      |> assign(:drone_count, 0)
      |> assign(:metrics, %{})
      |> assign(:page_title, "Drone Swarm Dashboard")
      |> load_initial_data()

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_metrics, socket) do
    metrics = DroneCoordinator.get_metrics()
    drone_count = DroneCoordinator.drone_count()

    socket =
      socket
      |> assign(:metrics, metrics)
      |> assign(:drone_count, drone_count)

    # Broadcast to all connected clients
    Phoenix.PubSub.broadcast(WebInterface.PubSub, "swarm_updates", {:metrics_update, metrics})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:metrics_update, metrics}, socket) do
    {:noreply, assign(socket, :metrics, metrics)}
  end

  @impl true
  def handle_event("spawn_drone", _params, socket) do
    case DroneCoordinator.spawn_drone() do
      {:ok, _pid, drone_id} ->
        socket = put_flash(socket, :info, "Spawned drone: #{drone_id}")
        {:noreply, socket}

      {:error, reason} ->
        socket = put_flash(socket, :error, "Failed to spawn drone: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("spawn_swarm", %{"count" => count_str}, socket) do
    case Integer.parse(count_str) do
      {count, ""} when count > 0 ->
        case DroneCoordinator.spawn_swarm(count) do
          {:ok, spawned_count} ->
            socket = put_flash(socket, :info, "Spawned #{spawned_count} drones")
            {:noreply, socket}

          {:error, reason} ->
            socket = put_flash(socket, :error, "Failed to spawn swarm: #{inspect(reason)}")
            {:noreply, socket}
        end

      _ ->
        socket = put_flash(socket, :error, "Invalid drone count")
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white">
      <!-- Header -->
      <div class="bg-gray-800 shadow-lg">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center py-6">
            <div class="flex items-center">
              <h1 class="text-3xl font-bold text-blue-400">Drone Swarm Control</h1>
              <span class="ml-4 px-3 py-1 bg-green-600 rounded-full text-sm">
                <%= @drone_count %> Active Drones
              </span>
            </div>
            <nav class="flex space-x-4">
              <.link navigate={~p"/"} class="text-blue-400 hover:text-blue-300">Dashboard</.link>
              <.link navigate={~p"/swarm"} class="text-gray-300 hover:text-white">Swarm View</.link>
              <.link navigate={~p"/metrics"} class="text-gray-300 hover:text-white">Metrics</.link>
              <.link navigate={~p"/controls"} class="text-gray-300 hover:text-white">Controls</.link>
            </nav>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Quick Actions -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4">Quick Spawn</h3>
            <button
              phx-click="spawn_drone"
              class="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mb-3"
            >
              Spawn Single Drone
            </button>
            <form phx-submit="spawn_swarm" class="flex gap-2">
              <input
                type="number"
                name="count"
                placeholder="Count"
                min="1"
                max="50"
                class="flex-1 bg-gray-700 border border-gray-600 rounded px-3 py-2 text-white"
              />
              <button
                type="submit"
                class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
              >
                Spawn Swarm
              </button>
            </form>
          </div>

          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4">System Status</h3>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span>Active Drones:</span>
                <span class="text-green-400"><%= @drone_count %></span>
              </div>
              <div class="flex justify-between">
                <span>System Load:</span>
                <span class="text-yellow-400">
                  <%= if @metrics[:system_load] do %>
                    <%= @metrics.system_load.run_queue %>
                  <% else %>
                    N/A
                  <% end %>
                </span>
              </div>
              <div class="flex justify-between">
                <span>Memory Usage:</span>
                <span class="text-blue-400">
                  <%= if @metrics[:system_load] do %>
                    <%= format_memory(@metrics.system_load.total_memory) %>
                  <% else %>
                    N/A
                  <% end %>
                </span>
              </div>
            </div>
          </div>

          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4">Swarm Metrics</h3>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span>Avg Velocity:</span>
                <span class="text-purple-400">
                  <%= if @metrics[:average_velocity] do %>
                    <%= Float.round(@metrics.average_velocity.magnitude, 2) %> m/s
                  <% else %>
                    N/A
                  <% end %>
                </span>
              </div>
              <div class="flex justify-between">
                <span>Swarm Spread:</span>
                <span class="text-orange-400">
                  <%= if @metrics[:swarm_spread] do %>
                    <%= Float.round(@metrics.swarm_spread.avg_distance, 2) %> m
                  <% else %>
                    N/A
                  <% end %>
                </span>
              </div>
              <div class="flex justify-between">
                <span>Avg Latency:</span>
                <span class="text-red-400">
                  <%= if @metrics[:latency_metrics] do %>
                    <%= Float.round(@metrics.latency_metrics.avg_update_delay, 2) %> ms
                  <% else %>
                    N/A
                  <% end %>
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Real-time Visualization -->
        <div class="bg-gray-800 rounded-lg p-6">
          <h3 class="text-xl font-semibold mb-4">3D Swarm Visualization</h3>
          <div id="swarm-canvas" class="w-full h-96 bg-black rounded border border-gray-600 relative">
            <div class="absolute inset-0 flex items-center justify-center text-gray-400">
              3D Visualization will render here
              <br />
              <small>Drone Count: <%= @drone_count %></small>
            </div>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="mt-8 bg-gray-800 rounded-lg p-6">
          <h3 class="text-xl font-semibold mb-4">System Activity</h3>
          <div class="space-y-2 max-h-48 overflow-y-auto">
            <div class="text-sm text-gray-300">
              <%= if @metrics[:timestamp] do %>
                [<%= format_timestamp(@metrics.timestamp) %>] Metrics updated
              <% else %>
                Waiting for metrics...
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_initial_data(socket) do
    metrics = DroneCoordinator.get_metrics()
    drone_count = DroneCoordinator.drone_count()

    socket
    |> assign(:metrics, metrics)
    |> assign(:drone_count, drone_count)
  end

  defp format_memory(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 2)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 2)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      true -> "#{bytes} B"
    end
  end
  defp format_memory(_), do: "N/A"

  defp format_timestamp(timestamp) when is_integer(timestamp) do
    timestamp
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_time()
    |> Time.to_string()
  end
  defp format_timestamp(_), do: "N/A"
end
