defmodule WebInterface.DroneController do
  use WebInterface, :controller

  def index(conn, _params) do
    drones = DroneCoordinator.list_drones()
    json(conn, %{drones: drones})
  end

  def show(conn, %{"id" => id}) do
    case DroneCoordinator.get_drone(id) do
      {:ok, drone} -> json(conn, %{drone: drone})
      {:error, :not_found} -> 
        conn
        |> put_status(:not_found)
        |> json(%{error: "Drone not found"})
    end
  end

  def create(conn, params) do
    case DroneCoordinator.spawn_drone(params) do
      {:ok, drone_id} -> 
        conn
        |> put_status(:created)
        |> json(%{drone_id: drone_id, status: "created"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def delete(conn, %{"id" => id}) do
    case DroneCoordinator.terminate_drone(id) do
      :ok -> json(conn, %{status: "terminated"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end
end
