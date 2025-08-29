import Config

# Development configuration
config :logger, level: :debug

# Drone coordinator configuration
config :drone_coordinator,
  max_drones: 50,
  simulation_speed: 1.0,
  world_bounds: {1000, 1000, 500}

# Web interface configuration  
config :web_interface, WebInterface.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_for_development_only_needs_to_be_at_least_64_bytes_long_to_work_properly_with_phoenix_sessions",
  live_view: [signing_salt: "GFzwposeeUTfjgCE"],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# Asset configuration
config :esbuild, :version, "0.17.11"
config :tailwind, :version, "3.2.7"

# Sensor processor configuration (commented out - not a standalone app)
# config :sensor_processor,
#   update_frequency: 60,  # Hz
#   sensor_noise: 0.1
