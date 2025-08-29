defmodule WebInterface.MetricsController do
  use WebInterface, :controller

  def index(conn, _params) do
    metrics = DroneCoordinator.get_metrics()
    json(conn, %{metrics: metrics})
  end

  def system(conn, _params) do
    system_metrics = %{
      memory_usage: :erlang.memory(),
      process_count: :erlang.system_info(:process_count),
      uptime: :erlang.statistics(:wall_clock) |> elem(0)
    }
    json(conn, %{system: system_metrics})
  end
end
