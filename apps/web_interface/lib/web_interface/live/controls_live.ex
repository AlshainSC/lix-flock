defmodule WebInterface.ControlsLive do
  use WebInterface, :live_view

  alias DroneCoordinator

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Swarm Controls")
      |> assign(:flocking_params, DroneCoordinator.get_flocking_params())
      |> assign(:spawn_count, 5)

    {:ok, socket}
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
  def handle_event("terminate_all", _params, socket) do
    case DroneCoordinator.terminate_all_drones() do
      :ok ->
        socket = put_flash(socket, :info, "All drones terminated")
        {:noreply, socket}
      {:error, reason} ->
        socket = put_flash(socket, :error, "Failed to terminate drones: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("set_spawn_count", %{"count" => count_str}, socket) do
    case Integer.parse(count_str) do
      {count, ""} when count > 0 and count <= 50 ->
        {:noreply, assign(socket, :spawn_count, count)}
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_flocking", params, socket) do
    flocking_params = %{
      separation_distance: String.to_float(params["separation_distance"] || "50.0"),
      alignment_distance: String.to_float(params["alignment_distance"] || "100.0"),
      cohesion_distance: String.to_float(params["cohesion_distance"] || "150.0"),
      max_speed: String.to_float(params["max_speed"] || "10.0")
    }

    case DroneCoordinator.update_flocking_params(flocking_params) do
      :ok ->
        socket = 
          socket
          |> assign(:flocking_params, flocking_params)
          |> put_flash(:info, "Flocking parameters updated")
        {:noreply, socket}
      {:error, reason} ->
        socket = put_flash(socket, :error, "Failed to update parameters: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white">
      <!-- Tablet-Friendly Header -->
      <div class="bg-gray-800 shadow-lg">
        <div class="px-4 py-4">
          <div class="flex justify-between items-center">
            <h1 class="text-2xl md:text-3xl font-bold text-blue-400">Drone Controls</h1>
            <div class="flex items-center space-x-3">
              <.link navigate={~p"/swarm"} class="bg-purple-600 hover:bg-purple-700 px-4 py-2 rounded text-sm font-medium">
                View Swarm
              </.link>
              <.link navigate={~p"/"} class="bg-gray-600 hover:bg-gray-700 px-4 py-2 rounded text-sm font-medium">
                Dashboard
              </.link>
            </div>
          </div>
        </div>
      </div>

      <div class="p-4 space-y-6">
        <!-- Large Touch-Friendly Spawn Controls -->
        <div class="bg-gray-800 rounded-xl p-6 shadow-lg">
          <h3 class="text-2xl font-semibold mb-6 text-green-400">Quick Spawn</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Single Drone Spawn -->
            <button
              phx-click="spawn_drone"
              class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-8 px-6 rounded-xl text-xl shadow-lg transform transition hover:scale-105 active:scale-95"
            >
              <div class="flex flex-col items-center">
                <div class="text-3xl mb-2">🚁</div>
                <div>Spawn Single Drone</div>
              </div>
            </button>

            <!-- Terminate All -->
            <button
              phx-click="terminate_all"
              class="bg-red-600 hover:bg-red-700 text-white font-bold py-8 px-6 rounded-xl text-xl shadow-lg transform transition hover:scale-105 active:scale-95"
              data-confirm="Are you sure you want to terminate all drones?"
            >
              <div class="flex flex-col items-center">
                <div class="text-3xl mb-2">🛑</div>
                <div>Terminate All</div>
              </div>
            </button>
          </div>
        </div>

        <!-- Swarm Spawn with Large Buttons -->
        <div class="bg-gray-800 rounded-xl p-6 shadow-lg">
          <h3 class="text-2xl font-semibold mb-6 text-green-400">Spawn Swarm</h3>
          
          <form phx-submit="spawn_swarm" class="space-y-6">
            <div>
              <label class="block text-lg font-medium mb-4">Number of Drones</label>
              <input
                type="number"
                name="count"
                value={@spawn_count}
                min="1"
                max="50"
                class="w-full bg-gray-700 border-2 border-gray-600 rounded-xl px-6 py-4 text-white text-xl"
                placeholder="Enter drone count"
              />
            </div>
            
            <!-- Quick Select Buttons -->
            <div class="grid grid-cols-3 md:grid-cols-5 gap-3">
              <button
                type="button"
                phx-click="set_spawn_count"
                phx-value-count="5"
                class="bg-green-600 hover:bg-green-700 text-white font-bold py-4 px-4 rounded-lg text-lg"
              >
                5
              </button>
              <button
                type="button"
                phx-click="set_spawn_count"
                phx-value-count="10"
                class="bg-green-600 hover:bg-green-700 text-white font-bold py-4 px-4 rounded-lg text-lg"
              >
                10
              </button>
              <button
                type="button"
                phx-click="set_spawn_count"
                phx-value-count="20"
                class="bg-green-600 hover:bg-green-700 text-white font-bold py-4 px-4 rounded-lg text-lg"
              >
                20
              </button>
              <button
                type="button"
                phx-click="set_spawn_count"
                phx-value-count="30"
                class="bg-green-600 hover:bg-green-700 text-white font-bold py-4 px-4 rounded-lg text-lg"
              >
                30
              </button>
              <button
                type="button"
                phx-click="set_spawn_count"
                phx-value-count="50"
                class="bg-green-600 hover:bg-green-700 text-white font-bold py-4 px-4 rounded-lg text-lg"
              >
                50
              </button>
            </div>

            <button
              type="submit"
              class="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-6 px-6 rounded-xl text-xl shadow-lg transform transition hover:scale-105 active:scale-95"
            >
              <div class="flex items-center justify-center">
                <div class="text-2xl mr-3">🚁🚁🚁</div>
                <div>Spawn Swarm</div>
              </div>
            </button>
          </form>
        </div>

        <!-- Tablet-Friendly Flocking Parameters -->
        <div class="bg-gray-800 rounded-xl p-6 shadow-lg">
          <h3 class="text-2xl font-semibold mb-6 text-purple-400">Flocking Parameters</h3>
          
          <form phx-submit="update_flocking" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-lg font-medium mb-3">Separation Distance (m)</label>
                <input
                  type="number"
                  name="separation_distance"
                  value={@flocking_params[:separation_distance] || 50.0}
                  step="0.1"
                  min="1"
                  max="200"
                  class="w-full bg-gray-700 border-2 border-gray-600 rounded-xl px-4 py-3 text-white text-lg"
                />
              </div>
              
              <div>
                <label class="block text-lg font-medium mb-3">Alignment Distance (m)</label>
                <input
                  type="number"
                  name="alignment_distance"
                  value={@flocking_params[:alignment_distance] || 100.0}
                  step="0.1"
                  min="1"
                  max="300"
                  class="w-full bg-gray-700 border-2 border-gray-600 rounded-xl px-4 py-3 text-white text-lg"
                />
              </div>
              
              <div>
                <label class="block text-lg font-medium mb-3">Cohesion Distance (m)</label>
                <input
                  type="number"
                  name="cohesion_distance"
                  value={@flocking_params[:cohesion_distance] || 150.0}
                  step="0.1"
                  min="1"
                  max="400"
                  class="w-full bg-gray-700 border-2 border-gray-600 rounded-xl px-4 py-3 text-white text-lg"
                />
              </div>
              
              <div>
                <label class="block text-lg font-medium mb-3">Max Speed (m/s)</label>
                <input
                  type="number"
                  name="max_speed"
                  value={@flocking_params[:max_speed] || 10.0}
                  step="0.1"
                  min="0.1"
                  max="50"
                  class="w-full bg-gray-700 border-2 border-gray-600 rounded-xl px-4 py-3 text-white text-lg"
                />
              </div>
            </div>
            
            <button
              type="submit"
              class="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-4 px-6 rounded-xl text-xl shadow-lg transform transition hover:scale-105"
            >
              Update Flocking Parameters
            </button>
          </form>
        </div>

        <!-- Emergency Controls with Large Touch Targets -->
        <div class="bg-red-900 border-2 border-red-600 rounded-xl p-6 shadow-lg">
          <h3 class="text-2xl font-semibold mb-6 text-red-400">Emergency Controls</h3>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button class="bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-6 px-4 rounded-xl text-lg shadow-lg transform transition hover:scale-105">
              ⚠️ Emergency Stop
            </button>
            <button class="bg-orange-600 hover:bg-orange-700 text-white font-bold py-6 px-4 rounded-xl text-lg shadow-lg transform transition hover:scale-105">
              🏠 Return to Base
            </button>
            <button class="bg-red-600 hover:bg-red-700 text-white font-bold py-6 px-4 rounded-xl text-lg shadow-lg transform transition hover:scale-105">
              🔄 System Reset
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
