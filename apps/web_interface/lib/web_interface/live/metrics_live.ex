defmodule WebInterface.MetricsLive do
  use WebInterface, :live_view

  alias DroneCoordinator

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebInterface.PubSub, "metrics_updates")
      :timer.send_interval(1000, self(), :update_metrics)
    end

    socket =
      socket
      |> assign(:metrics, %{})
      |> assign(:system_metrics, %{})
      |> assign(:page_title, "System Metrics")
      |> load_metrics()

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_metrics, socket) do
    socket = load_metrics(socket)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 class="text-3xl font-bold text-blue-400 mb-8">System Metrics</h1>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <!-- Drone Metrics -->
          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4 text-blue-400">Drone Metrics</h3>
            <div class="space-y-3">
              <div class="flex justify-between">
                <span>Active Drones:</span>
                <span class="text-green-400 font-bold"><%= @metrics[:drone_count] || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span>Spawned Total:</span>
                <span class="text-blue-400"><%= @metrics[:total_spawned] || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span>Terminated:</span>
                <span class="text-red-400"><%= @metrics[:total_terminated] || 0 %></span>
              </div>
            </div>
          </div>

          <!-- System Performance -->
          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4 text-green-400">System Performance</h3>
            <div class="space-y-3">
              <div class="flex justify-between">
                <span>Memory Usage:</span>
                <span class="text-yellow-400"><%= format_memory(@system_metrics[:memory_total]) %></span>
              </div>
              <div class="flex justify-between">
                <span>Process Count:</span>
                <span class="text-purple-400"><%= @system_metrics[:process_count] || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span>Uptime:</span>
                <span class="text-blue-400"><%= format_uptime(@system_metrics[:uptime]) %></span>
              </div>
            </div>
          </div>

          <!-- Flocking Metrics -->
          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4 text-purple-400">Flocking Metrics</h3>
            <div class="space-y-3">
              <div class="flex justify-between">
                <span>Avg Velocity:</span>
                <span class="text-green-400"><%= @metrics[:avg_velocity] || "0.0" %> m/s</span>
              </div>
              <div class="flex justify-between">
                <span>Cohesion:</span>
                <span class="text-blue-400"><%= @metrics[:cohesion_factor] || "N/A" %></span>
              </div>
              <div class="flex justify-between">
                <span>Separation:</span>
                <span class="text-orange-400"><%= @metrics[:separation_factor] || "N/A" %></span>
              </div>
            </div>
          </div>

          <!-- Sensor Processing -->
          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4 text-orange-400">Sensor Processing</h3>
            <div class="space-y-3">
              <div class="flex justify-between">
                <span>Visual Processed:</span>
                <span class="text-green-400"><%= @metrics[:visual_processed] || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span>Audio Processed:</span>
                <span class="text-blue-400"><%= @metrics[:audio_processed] || 0 %></span>
              </div>
              <div class="flex justify-between">
                <span>Radar Processed:</span>
                <span class="text-purple-400"><%= @metrics[:radar_processed] || 0 %></span>
              </div>
            </div>
          </div>

          <!-- Latency Metrics -->
          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4 text-red-400">Latency Metrics</h3>
            <div class="space-y-3">
              <div class="flex justify-between">
                <span>Avg Processing:</span>
                <span class="text-yellow-400"><%= @metrics[:avg_processing_time] || "0" %> ms</span>
              </div>
              <div class="flex justify-between">
                <span>Max Latency:</span>
                <span class="text-red-400"><%= @metrics[:max_latency] || "0" %> ms</span>
              </div>
              <div class="flex justify-between">
                <span>Min Latency:</span>
                <span class="text-green-400"><%= @metrics[:min_latency] || "0" %> ms</span>
              </div>
            </div>
          </div>

          <!-- Real-time Chart -->
          <div class="bg-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold mb-4 text-cyan-400">Real-time Activity</h3>
            <div class="h-32 bg-black rounded border border-gray-600 flex items-center justify-center">
              <span class="text-gray-400">Live metrics chart</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_metrics(socket) do
    metrics = DroneCoordinator.get_metrics()
    system_metrics = %{
      memory_total: :erlang.memory(:total),
      process_count: :erlang.system_info(:process_count),
      uptime: :erlang.statistics(:wall_clock) |> elem(0)
    }

    socket
    |> assign(:metrics, metrics)
    |> assign(:system_metrics, system_metrics)
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

  defp format_uptime(milliseconds) when is_integer(milliseconds) do
    seconds = div(milliseconds, 1000)
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    "#{hours}h #{rem(minutes, 60)}m"
  end
  defp format_uptime(_), do: "N/A"
end
