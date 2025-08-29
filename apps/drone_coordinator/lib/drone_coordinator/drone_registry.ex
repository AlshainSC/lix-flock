defmodule DroneCoordinator.DroneRegistry do
  @moduledoc """
  Registry for drone processes in the swarm.
  Provides process registration and lookup for individual drones.
  """

  def child_spec(_opts) do
    Registry.child_spec(
      keys: :unique,
      name: __MODULE__
    )
  end
end
