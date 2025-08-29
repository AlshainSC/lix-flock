# Lix-Flock Setup Script for Windows
# This script installs all required dependencies and sets up the project

Write-Host "=== Lix-Flock Drone Swarm Simulation Setup ===" -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator to install dependencies." -ForegroundColor Red
    exit 1
}

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

# Install Chocolatey if not present
if (-not (Test-Command choco)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install Elixir
if (-not (Test-Command elixir)) {
    Write-Host "Installing Elixir..." -ForegroundColor Yellow
    choco install elixir -y
}

# Install Erlang (if not already installed with Elixir)
if (-not (Test-Command erl)) {
    Write-Host "Installing Erlang..." -ForegroundColor Yellow
    choco install erlang -y
}

# Install Rust
if (-not (Test-Command rustc)) {
    Write-Host "Installing Rust..." -ForegroundColor Yellow
    choco install rust -y
}

# Install Node.js
if (-not (Test-Command node)) {
    Write-Host "Installing Node.js..." -ForegroundColor Yellow
    choco install nodejs -y
}

# Refresh environment variables
Write-Host "Refreshing environment variables..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "=== Installation Complete ===" -ForegroundColor Green
Write-Host "Please restart your terminal and run setup-project.ps1 to continue." -ForegroundColor Cyan
