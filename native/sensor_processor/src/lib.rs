use rustler::{NifResult, NifStruct};
use serde::{Deserialize, Serialize};

mod sensors;
mod flocking;
mod utils;

use sensors::*;
use flocking::*;

rustler::init!("Elixir.SensorProcessor");

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "DronePosition"]
pub struct DronePosition {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "DroneVelocity"]
pub struct DroneVelocity {
    pub vx: f64,
    pub vy: f64,
    pub vz: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "DroneState"]
pub struct DroneState {
    pub id: String,
    pub position: DronePosition,
    pub velocity: DroneVelocity,
    pub timestamp: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "SensorData"]
pub struct SensorData {
    pub visual: VisualData,
    pub audio: AudioData,
    pub radar: RadarData,
    pub lidar: LidarData,
    pub timestamp: u64,
}

// NIF functions exposed to Elixir

#[rustler::nif]
fn process_visual_data(raw_data: Vec<u8>) -> NifResult<VisualData> {
    let processed = sensors::process_visual_spectrum(&raw_data);
    Ok(processed)
}

#[rustler::nif]
fn process_audio_data(raw_data: Vec<f32>) -> NifResult<AudioData> {
    let processed = sensors::process_audio_spectrum(&raw_data);
    Ok(processed)
}

#[rustler::nif]
fn process_radar_data(raw_data: Vec<f32>) -> NifResult<RadarData> {
    let processed = sensors::process_radar_readings(&raw_data);
    Ok(processed)
}

#[rustler::nif]
fn process_lidar_data(raw_data: Vec<(f32, f32, f32)>) -> NifResult<LidarData> {
    let processed = sensors::process_lidar_pointcloud(&raw_data);
    Ok(processed)
}

#[rustler::nif]
fn calculate_flocking_forces(
    drone_state: DroneState,
    neighbors: Vec<DroneState>,
    params: FlockingParams
) -> NifResult<(f64, f64, f64)> {
    let force = flocking::calculate_boids_forces(&drone_state, &neighbors, &params);
    Ok((force.x, force.y, force.z))
}

#[rustler::nif]
fn generate_mock_sensor_data(drone_id: String, noise_level: f64) -> NifResult<SensorData> {
    let data = sensors::generate_mock_data(&drone_id, noise_level);
    Ok(data)
}
