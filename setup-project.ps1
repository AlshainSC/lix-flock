# Project Setup Script - Run after dependencies are installed
# This script sets up the Lix-Flock project dependencies and builds the application

Write-Host "=== Lix-Flock Project Setup ===" -ForegroundColor Cyan

$projectRoot = $PSScriptRoot

# Function to check if a command exists
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Verify required tools are installed
$requiredTools = @("mix", "cargo", "node")
foreach ($tool in $requiredTools) {
    if (-not (Test-Command $tool)) {
        Write-Host "Error: $tool is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please run setup.ps1 first to install dependencies" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "All required tools found!" -ForegroundColor Green

# Set location to project root
Set-Location $projectRoot

# Get Elixir dependencies
Write-Host "Installing Elixir dependencies..." -ForegroundColor Yellow
try {
    mix deps.get
    if ($LASTEXITCODE -ne 0) { throw "mix deps.get failed" }
} catch {
    Write-Host "Error installing Elixir dependencies: $_" -ForegroundColor Red
    exit 1
}

# Build Rust components
Write-Host "Building Rust sensor processor..." -ForegroundColor Yellow
Set-Location "native/sensor_processor"
try {
    cargo build --release
    if ($LASTEXITCODE -ne 0) { throw "cargo build failed" }
} catch {
    Write-Host "Error building Rust components: $_" -ForegroundColor Red
    exit 1
}

# Return to project root
Set-Location $projectRoot

# Setup web interface assets
Write-Host "Setting up web interface assets..." -ForegroundColor Yellow
Set-Location "apps/web_interface"
try {
    mix assets.setup
    if ($LASTEXITCODE -ne 0) { throw "mix assets.setup failed" }
} catch {
    Write-Host "Error setting up assets: $_" -ForegroundColor Red
    exit 1
}

# Build assets
Write-Host "Building web assets..." -ForegroundColor Yellow
try {
    mix assets.build
    if ($LASTEXITCODE -ne 0) { throw "mix assets.build failed" }
} catch {
    Write-Host "Error building assets: $_" -ForegroundColor Red
    exit 1
}

# Return to project root
Set-Location $projectRoot

Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "To start the application:" -ForegroundColor Cyan
Write-Host "  mix phx.server" -ForegroundColor White
Write-Host ""
Write-Host "Then open your browser to:" -ForegroundColor Cyan
Write-Host "  http://localhost:4000" -ForegroundColor White
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Cyan
Write-Host "  mix test              # Run tests" -ForegroundColor White
Write-Host "  mix format            # Format code" -ForegroundColor White
Write-Host "  iex -S mix phx.server # Start with interactive shell" -ForegroundColor White
