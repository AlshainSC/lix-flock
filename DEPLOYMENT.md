# Deployment Guide for Lix-Flock

This guide provides multiple deployment options for the Lix-Flock drone swarm simulation.

## Option 1: Local Development Setup (Windows)

### Prerequisites Installation
Run as Administrator:
```powershell
.\setup.ps1
```

This installs:
- Elixir 1.15+ with OTP 26+
- Rust 1.70+
- Node.js 18+
- Chocolatey package manager

### Project Setup
After restarting your terminal:
```powershell
.\setup-project.ps1
```

### Running the Application
```bash
mix phx.server
```

Access at: http://localhost:4000

## Option 2: Docker Deployment

### Quick Start
```bash
# Build and run with Docker Compose
docker-compose up --build

# Access the application
# Main app: http://localhost:4000
# Grafana (optional): http://localhost:3000 (admin/admin123)
# InfluxDB (optional): http://localhost:8086 (admin/password123)
```

### Production Docker
```bash
# Build production image
docker build -t lix-flock:latest .

# Run with environment variables
docker run -d \
  -p 4000:4000 \
  -e SECRET_KEY_BASE="your-secret-key-here" \
  -e MAX_DRONES=200 \
  -e SENSOR_FREQUENCY=120 \
  --name lix-flock \
  lix-flock:latest
```

## Option 3: Cloud Deployment

### Fly.io Deployment
```bash
# Install flyctl
# https://fly.io/docs/getting-started/installing-flyctl/

# Initialize Fly app
fly launch

# Deploy
fly deploy
```

### Railway Deployment
1. Connect your GitHub repository to Railway
2. Set environment variables:
   - `SECRET_KEY_BASE`: Generate with `mix phx.gen.secret`
   - `MAX_DRONES`: 100 (or desired limit)
   - `SENSOR_FREQUENCY`: 60

### Heroku Deployment
```bash
# Create Heroku app
heroku create your-app-name

# Add buildpacks
heroku buildpacks:add https://github.com/HashNuke/heroku-buildpack-elixir
heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static
heroku buildpacks:add https://github.com/emk/heroku-buildpack-rust

# Set environment variables
heroku config:set SECRET_KEY_BASE="$(mix phx.gen.secret)"
heroku config:set MAX_DRONES=100

# Deploy
git push heroku main
```

## Environment Variables

### Required
- `SECRET_KEY_BASE`: Phoenix secret key (generate with `mix phx.gen.secret`)

### Optional
- `PORT`: Server port (default: 4000)
- `PHX_HOST`: Host name (default: localhost)
- `MAX_DRONES`: Maximum drone count (default: 200)
- `SIMULATION_SPEED`: Speed multiplier (default: 1.0)
- `SENSOR_FREQUENCY`: Sensor update Hz (default: 120)
- `SENSOR_NOISE`: Noise level 0-1 (default: 0.05)
- `WORLD_X`, `WORLD_Y`, `WORLD_Z`: World boundaries (default: 2000, 2000, 1000)

## Performance Tuning

### For High Drone Counts (500+)
```bash
# Increase Erlang VM limits
export ERL_MAX_PORTS=65536
export ERL_MAX_ETS_TABLES=32768

# Adjust sensor frequency
export SENSOR_FREQUENCY=30  # Lower frequency for more drones
```

### Memory Optimization
```bash
# Reduce world size for memory efficiency
export WORLD_X=1000
export WORLD_Y=1000
export WORLD_Z=500
export MAX_DRONES=100
```

## Monitoring and Observability

### Built-in Monitoring
- Phoenix LiveDashboard: `/dev/dashboard` (development)
- Real-time metrics in main dashboard
- Telemetry integration

### External Monitoring (Docker Compose)
- **Grafana**: Advanced dashboards and alerting
- **InfluxDB**: Time-series metrics storage
- **Prometheus**: Alternative metrics collection (add to docker-compose.yml)

### Custom Metrics Integration
```elixir
# Add custom telemetry events
:telemetry.execute([:drone_coordinator, :custom_metric], %{value: 42}, %{drone_id: "drone_123"})
```

## Troubleshooting

### Common Issues

**Rust compilation fails:**
```bash
# Update Rust toolchain
rustup update
cd native/sensor_processor
cargo clean && cargo build --release
```

**Memory issues with many drones:**
```bash
# Reduce drone count and sensor frequency
export MAX_DRONES=50
export SENSOR_FREQUENCY=30
```

**Phoenix asset compilation:**
```bash
cd apps/web_interface
rm -rf node_modules
npm install
mix assets.build
```

### Performance Debugging
```bash
# Start with observer for system monitoring
iex -S mix phx.server
# In IEx console:
:observer.start()
```

### Log Analysis
```bash
# Increase log level for debugging
export LOG_LEVEL=debug

# Filter drone-specific logs
docker logs lix-flock 2>&1 | grep "drone_"
```

## Security Considerations

### Production Checklist
- [ ] Generate strong `SECRET_KEY_BASE`
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Set up firewall rules (only expose necessary ports)
- [ ] Regular security updates for base images
- [ ] Monitor resource usage and set limits
- [ ] Implement rate limiting for API endpoints
- [ ] Set up log aggregation and monitoring

### Network Security
```bash
# Restrict Docker network access
docker network create --driver bridge --subnet=172.20.0.0/16 lix-flock-net
```

## Scaling

### Horizontal Scaling
- Deploy multiple instances behind a load balancer
- Use Redis for shared state (requires code modifications)
- Implement distributed drone coordination

### Vertical Scaling
- Increase CPU/memory allocation
- Optimize Rust algorithms for better performance
- Use faster storage for metrics collection

## Backup and Recovery

### Configuration Backup
```bash
# Backup configuration
tar -czf lix-flock-config-$(date +%Y%m%d).tar.gz config/

# Backup metrics (if using InfluxDB)
docker exec influxdb influx backup /backup
```

### Disaster Recovery
- Store configuration in version control
- Automate deployment with CI/CD
- Regular testing of backup restoration
- Monitor system health and set up alerts
