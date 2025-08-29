defmodule LixFlock.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.30"},
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd native/sensor_processor cargo build --release"],
      test: ["test"]
    ]
  end

  defp releases do
    [
      lix_flock: [
        applications: [
          drone_coordinator: :permanent,
          web_interface: :permanent
        ]
      ]
    ]
  end
end
