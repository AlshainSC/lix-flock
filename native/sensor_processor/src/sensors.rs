use serde::{Deserialize, Serialize};
use rustler::NifStruct;
use rand::Rng;

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "VisualData"]
pub struct VisualData {
    pub rgb: (u8, u8, u8),
    pub infrared: f32,
    pub uv: f32,
    pub brightness: f32,
    pub contrast: f32,
    pub detected_objects: Vec<DetectedObject>,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "AudioData"]
pub struct AudioData {
    pub amplitude: f32,
    pub frequency_spectrum: Vec<f32>,
    pub direction: f32,
    pub detected_sounds: Vec<SoundSignature>,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "RadarData"]
pub struct RadarData {
    pub range_readings: Vec<f32>,
    pub velocity_readings: Vec<f32>,
    pub detected_objects: Vec<RadarTarget>,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "LidarData"]
pub struct LidarData {
    pub point_cloud: Vec<(f32, f32, f32)>,
    pub intensity: Vec<f32>,
    pub detected_obstacles: Vec<Obstacle>,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "DetectedObject"]
pub struct DetectedObject {
    pub object_type: String,
    pub confidence: f32,
    pub bounding_box: (f32, f32, f32, f32),
    pub distance: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "SoundSignature"]
pub struct SoundSignature {
    pub sound_type: String,
    pub frequency: f32,
    pub amplitude: f32,
    pub direction: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "RadarTarget"]
pub struct RadarTarget {
    pub distance: f32,
    pub velocity: f32,
    pub angle: f32,
    pub size: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "Obstacle"]
pub struct Obstacle {
    pub position: (f32, f32, f32),
    pub size: f32,
    pub obstacle_type: String,
}

use crate::SensorData;

pub fn process_visual_spectrum(raw_data: &[u8]) -> VisualData {
    // Simulate advanced visual processing
    let mut rng = rand::thread_rng();
    
    // Extract RGB from raw data (simplified)
    let rgb = if raw_data.len() >= 3 {
        (raw_data[0], raw_data[1], raw_data[2])
    } else {
        (128, 128, 128)
    };
    
    // Simulate infrared and UV processing
    let infrared = raw_data.iter().map(|&x| x as f32).sum::<f32>() / raw_data.len() as f32 * 0.3;
    let uv = raw_data.iter().map(|&x| x as f32).sum::<f32>() / raw_data.len() as f32 * 0.1;
    
    // Calculate brightness and contrast
    let brightness = raw_data.iter().map(|&x| x as f32).sum::<f32>() / (raw_data.len() as f32 * 255.0);
    let mean = brightness * 255.0;
    let variance = raw_data.iter()
        .map(|&x| (x as f32 - mean).powi(2))
        .sum::<f32>() / raw_data.len() as f32;
    let contrast = variance.sqrt() / 255.0;
    
    // Simulate object detection
    let detected_objects = if rng.gen::<f32>() < 0.3 {
        vec![DetectedObject {
            object_type: "drone".to_string(),
            confidence: rng.gen_range(0.7..0.95),
            bounding_box: (
                rng.gen_range(0.0..0.8),
                rng.gen_range(0.0..0.8),
                rng.gen_range(0.1..0.3),
                rng.gen_range(0.1..0.3),
            ),
            distance: rng.gen_range(10.0..200.0),
        }]
    } else {
        vec![]
    };
    
    VisualData {
        rgb,
        infrared,
        uv,
        brightness,
        contrast,
        detected_objects,
    }
}

pub fn process_audio_spectrum(raw_data: &[f32]) -> AudioData {
    let mut rng = rand::thread_rng();
    
    // Calculate amplitude
    let amplitude = raw_data.iter().map(|x| x.abs()).sum::<f32>() / raw_data.len() as f32;
    
    // Simulate FFT for frequency spectrum (simplified)
    let frequency_spectrum: Vec<f32> = (0..10)
        .map(|i| {
            let freq_range = i as f32 * 1000.0..((i + 1) as f32 * 1000.0);
            raw_data.iter()
                .enumerate()
                .filter(|(idx, _)| {
                    let freq = *idx as f32 * 10.0; // Simplified frequency mapping
                    freq_range.contains(&freq)
                })
                .map(|(_, &val)| val.abs())
                .sum::<f32>()
        })
        .collect();
    
    // Estimate direction using phase differences (simplified)
    let direction = if raw_data.len() > 1 {
        (raw_data[0] - raw_data[1]).atan2(raw_data[0] + raw_data[1])
    } else {
        0.0
    };
    
    // Detect sound signatures
    let detected_sounds = if amplitude > 0.5 {
        vec![SoundSignature {
            sound_type: "motor".to_string(),
            frequency: rng.gen_range(100.0..500.0),
            amplitude,
            direction,
        }]
    } else {
        vec![]
    };
    
    AudioData {
        amplitude,
        frequency_spectrum,
        direction,
        detected_sounds,
    }
}

pub fn process_radar_readings(raw_data: &[f32]) -> RadarData {
    let mut rng = rand::thread_rng();
    
    // Process range readings (distance measurements)
    let range_readings: Vec<f32> = raw_data.iter()
        .take(8) // 8 directional readings
        .map(|&x| x.abs() * 100.0) // Convert to meters
        .collect();
    
    // Calculate velocity readings using Doppler effect simulation
    let velocity_readings: Vec<f32> = raw_data.iter()
        .skip(8)
        .take(8)
        .map(|&x| x * 10.0) // Convert to m/s
        .collect();
    
    // Detect radar targets
    let detected_objects: Vec<RadarTarget> = range_readings.iter()
        .enumerate()
        .filter(|(_, &distance)| distance < 150.0 && distance > 5.0)
        .map(|(idx, &distance)| RadarTarget {
            distance,
            velocity: velocity_readings.get(idx).copied().unwrap_or(0.0),
            angle: idx as f32 * 45.0, // 8 directions, 45° apart
            size: rng.gen_range(0.5..3.0),
        })
        .collect();
    
    RadarData {
        range_readings,
        velocity_readings,
        detected_objects,
    }
}

pub fn process_lidar_pointcloud(raw_data: &[(f32, f32, f32)]) -> LidarData {
    let mut rng = rand::thread_rng();
    
    // Filter and process point cloud
    let point_cloud: Vec<(f32, f32, f32)> = raw_data.iter()
        .filter(|(x, y, z)| {
            let distance = (x*x + y*y + z*z).sqrt();
            distance > 0.5 && distance < 200.0 // Filter valid range
        })
        .cloned()
        .collect();
    
    // Calculate intensity values
    let intensity: Vec<f32> = point_cloud.iter()
        .map(|(x, y, z)| {
            let distance = (x*x + y*y + z*z).sqrt();
            (1.0 / (distance + 1.0)).min(1.0) // Intensity decreases with distance
        })
        .collect();
    
    // Detect obstacles using clustering (simplified)
    let detected_obstacles: Vec<Obstacle> = cluster_points(&point_cloud)
        .into_iter()
        .filter(|cluster| cluster.len() > 5) // Minimum points for obstacle
        .map(|cluster| {
            let center = calculate_cluster_center(&cluster);
            let size = calculate_cluster_size(&cluster, &center);
            
            Obstacle {
                position: center,
                size,
                obstacle_type: classify_obstacle(size),
            }
        })
        .collect();
    
    LidarData {
        point_cloud,
        intensity,
        detected_obstacles,
    }
}

pub fn generate_mock_data(drone_id: &str, noise_level: f64) -> SensorData {
    let mut rng = rand::thread_rng();
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64;
    
    // Generate mock raw data
    let visual_raw: Vec<u8> = (0..100).map(|_| rng.gen()).collect();
    let audio_raw: Vec<f32> = (0..50).map(|_| rng.gen_range(-1.0..1.0)).collect();
    let radar_raw: Vec<f32> = (0..16).map(|_| rng.gen_range(0.0..2.0)).collect();
    let lidar_raw: Vec<(f32, f32, f32)> = (0..360).map(|i| {
        let angle = i as f32 * std::f32::consts::PI / 180.0;
        let distance = rng.gen_range(10.0..100.0);
        (
            distance * angle.cos(),
            distance * angle.sin(),
            rng.gen_range(-5.0..5.0),
        )
    }).collect();
    
    SensorData {
        visual: process_visual_spectrum(&visual_raw),
        audio: process_audio_spectrum(&audio_raw),
        radar: process_radar_readings(&radar_raw),
        lidar: process_lidar_pointcloud(&lidar_raw),
        timestamp,
    }
}

// Helper functions for LiDAR processing

fn cluster_points(points: &[(f32, f32, f32)]) -> Vec<Vec<(f32, f32, f32)>> {
    // Simplified clustering algorithm
    let mut clusters = Vec::new();
    let mut used = vec![false; points.len()];
    
    for (i, &point) in points.iter().enumerate() {
        if used[i] {
            continue;
        }
        
        let mut cluster = vec![point];
        used[i] = true;
        
        // Find nearby points
        for (j, &other_point) in points.iter().enumerate() {
            if used[j] {
                continue;
            }
            
            let distance = calculate_distance(point, other_point);
            if distance < 2.0 { // Clustering threshold
                cluster.push(other_point);
                used[j] = true;
            }
        }
        
        clusters.push(cluster);
    }
    
    clusters
}

fn calculate_cluster_center(cluster: &[(f32, f32, f32)]) -> (f32, f32, f32) {
    let sum = cluster.iter().fold((0.0, 0.0, 0.0), |acc, &point| {
        (acc.0 + point.0, acc.1 + point.1, acc.2 + point.2)
    });
    
    let len = cluster.len() as f32;
    (sum.0 / len, sum.1 / len, sum.2 / len)
}

fn calculate_cluster_size(cluster: &[(f32, f32, f32)], center: &(f32, f32, f32)) -> f32 {
    cluster.iter()
        .map(|&point| calculate_distance(point, *center))
        .fold(0.0, f32::max)
}

fn calculate_distance(p1: (f32, f32, f32), p2: (f32, f32, f32)) -> f32 {
    let dx = p1.0 - p2.0;
    let dy = p1.1 - p2.1;
    let dz = p1.2 - p2.2;
    (dx*dx + dy*dy + dz*dz).sqrt()
}

fn classify_obstacle(size: f32) -> String {
    match size {
        s if s < 1.0 => "small_object".to_string(),
        s if s < 5.0 => "medium_object".to_string(),
        s if s < 20.0 => "large_object".to_string(),
        _ => "building".to_string(),
    }
}
