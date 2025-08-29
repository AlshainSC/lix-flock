defmodule WebInterface.FlockingController do
  use WebInterface, :controller

  def show(conn, _params) do
    params = DroneCoordinator.get_flocking_params()
    json(conn, %{flocking_params: params})
  end

  def update(conn, params) do
    case DroneCoordinator.update_flocking_params(params) do
      :ok -> json(conn, %{status: "updated"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end
end
