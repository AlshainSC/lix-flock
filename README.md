# Lix-Flock: Drone Swarm Flocking Simulation

A proof-of-concept flocking simulation for autonomous drone swarms using Elixir and Rust. This project demonstrates real-time data handling, distributed coordination, and advanced sensor processing for drone swarm applications.

## Architecture

- **Elixir/OTP**: Manages drone processes, coordination, and real-time data streaming
- **Rust**: High-performance sensor data parsing and flocking calculations via NIFs
- **Phoenix LiveView**: Real-time web interface for visualization and monitoring
- **Telemetry**: Comprehensive performance monitoring and metrics collection

## Features

### Core Functionality
- **Flocking Algorithm**: Reynolds' boids implementation (separation, alignment, cohesion)
- **Multi-Sensor Simulation**: Visual (RGB/IR/UV), Audio, Radar, LiDAR data processing
- **Real-time Visualization**: 3D drone positioning and swarm behavior
- **Performance Monitoring**: Latency tracking, system metrics, and telemetry

### Technical Highlights
- **Fault-Tolerant**: Elixir's "let it crash" philosophy ensures system resilience
- **Scalable**: Dynamic drone spawning/termination during runtime
- **High-Performance**: Rust handles computationally intensive operations
- **Real-time**: Sub-100ms data processing and visualization updates

## Project Structure

```
lix-flock/
├── apps/
│   ├── drone_coordinator/     # Elixir OTP application
│   │   ├── lib/
│   │   │   ├── drone.ex              # Individual drone GenServer
│   │   │   ├── swarm_supervisor.ex   # Dynamic drone management
│   │   │   ├── flocking_coordinator.ex # Swarm behavior coordination
│   │   │   ├── sensor_data_manager.ex # Sensor data distribution
│   │   │   └── metrics_collector.ex   # Performance monitoring
│   │   └── mix.exs
│   └── web_interface/         # Phoenix LiveView application
│       ├── lib/
│       │   ├── live/
│       │   │   └── dashboard_live.ex  # Main dashboard interface
│       │   ├── data_broadcaster.ex    # Real-time data streaming
│       │   └── core_components.ex     # UI components
│       └── mix.exs
├── native/
│   └── sensor_processor/      # Rust NIF modules
│       ├── src/
│       │   ├── sensors.rs     # Sensor data processing
│       │   ├── flocking.rs    # Flocking algorithm implementation
│       │   └── utils.rs       # Utility functions
│       └── Cargo.toml
├── config/                    # Environment configurations
└── mix.exs                   # Umbrella project configuration
```

## Quick Start

### Prerequisites
- Elixir 1.15+ with OTP 26+
- Rust 1.70+
- Node.js 18+ (for asset compilation)

### Installation

1. **Clone and setup dependencies:**
   ```bash
   git clone <repository-url>
   cd lix-flock
   mix deps.get
   ```

2. **Build Rust components:**
   ```bash
   cd native/sensor_processor
   cargo build --release
   cd ../..
   ```

3. **Setup web assets:**
   ```bash
   cd apps/web_interface
   mix assets.setup
   cd ../..
   ```

4. **Start the application:**
   ```bash
   mix phx.server
   ```

5. **Access the dashboard:**
   Open http://localhost:4000 in your browser

### Basic Usage

1. **Spawn drones**: Use the dashboard to spawn individual drones or entire swarms
2. **Monitor behavior**: Watch real-time flocking behavior in the 3D visualization
3. **Adjust parameters**: Modify flocking parameters to see behavioral changes
4. **Monitor performance**: Track system metrics and latency in real-time

## Configuration

### Environment Settings

**Development** (`config/dev.exs`):
- Max drones: 50
- Update frequency: 60 Hz
- Debug logging enabled

**Production** (`config/prod.exs`):
- Max drones: 200
- Update frequency: 120 Hz
- Optimized for performance

### Flocking Parameters

Adjust these parameters to modify swarm behavior:

```elixir
# In Elixir console or via web interface
DroneCoordinator.update_flocking_parameters(%{
  neighbor_radius: 100.0,      # Detection range for neighbors
  separation_radius: 50.0,     # Minimum distance between drones
  max_speed: 50.0,            # Maximum drone velocity
  max_force: 10.0,            # Maximum steering force
  separation_weight: 2.0,      # Avoidance behavior strength
  alignment_weight: 1.0,       # Velocity matching strength
  cohesion_weight: 1.0        # Group attraction strength
})
```

## API Reference

### Drone Management
```elixir
# Spawn a single drone
{:ok, pid, drone_id} = DroneCoordinator.spawn_drone()

# Spawn multiple drones
{:ok, count} = DroneCoordinator.spawn_swarm(10)

# List active drones
drone_ids = DroneCoordinator.list_drones()

# Terminate a drone
:ok = DroneCoordinator.terminate_drone(drone_id)
```

### Metrics and Monitoring
```elixir
# Get current swarm metrics
metrics = DroneCoordinator.get_metrics()

# Get metrics history (last 60 seconds)
history = DroneCoordinator.get_metrics_history(60_000)
```

### Sensor Data Processing
```elixir
# Access sensor data for a specific drone
sensor_data = DroneCoordinator.SensorDataManager.get_sensor_data(drone_id, :visual)
```

## Development

### Running Tests
```bash
mix test
```

### Code Quality
```bash
# Format code
mix format

# Static analysis
mix credo

# Type checking (if using Dialyzer)
mix dialyzer
```

### Adding New Sensor Types

1. **Extend Rust sensor module** (`native/sensor_processor/src/sensors.rs`):
   ```rust
   pub fn process_new_sensor_data(raw_data: &[u8]) -> NewSensorData {
       // Implementation
   }
   ```

2. **Add NIF function** (`native/sensor_processor/src/lib.rs`):
   ```rust
   #[rustler::nif]
   fn process_new_sensor(raw_data: Vec<u8>) -> NifResult<HashMap<String, Term>> {
       // Implementation
   }
   ```

3. **Update Elixir sensor manager** (`apps/drone_coordinator/lib/drone_coordinator/sensor_data_manager.ex`):
   ```elixir
   defp generate_new_sensor_data(noise_level) do
       # Mock data generation
   end
   ```

## Performance Considerations

### Optimization Tips
- **Drone Count**: Start with 10-20 drones for development, scale up gradually
- **Update Frequency**: Reduce sensor update frequency for better performance
- **Neighbor Radius**: Smaller radius reduces computational overhead
- **Visualization**: Disable 3D rendering for headless operation

### Monitoring
- Use Phoenix LiveDashboard at `/dev/dashboard` for system insights
- Monitor memory usage and process counts
- Track average update latencies in the metrics dashboard

## Troubleshooting

### Common Issues

**Rust compilation errors:**
```bash
# Ensure Rust toolchain is up to date
rustup update
# Clean and rebuild
cd native/sensor_processor && cargo clean && cargo build --release
```

**Phoenix asset compilation:**
```bash
# Reinstall Node dependencies
cd apps/web_interface && rm -rf node_modules && npm install
```

**High memory usage:**
- Reduce max_drones in configuration
- Lower sensor update frequency
- Check for drone process leaks

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Reynolds' Boids algorithm for flocking behavior
- Elixir/OTP for fault-tolerant distributed systems
- Rust for high-performance computing
- Phoenix LiveView for real-time web interfaces
