import Config

# Production configuration
config :logger, level: :warn

# Drone coordinator configuration
config :drone_coordinator,
  max_drones: 200,
  simulation_speed: 1.0,
  world_bounds: {2000, 2000, 1000}

# Web interface configuration  
config :web_interface, WebInterface.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Sensor processor configuration
config :sensor_processor,
  update_frequency: 120,  # Hz
  sensor_noise: 0.05
