import Config

# Test configuration
config :logger, level: :warn

# Drone coordinator configuration
config :drone_coordinator,
  max_drones: 10,
  simulation_speed: 10.0,  # Faster for tests
  world_bounds: {100, 100, 50}

# Web interface configuration  
config :web_interface, WebInterface.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

# Sensor processor configuration
config :sensor_processor,
  update_frequency: 10,  # Hz - Lower for tests
  sensor_noise: 0.0  # No noise in tests
