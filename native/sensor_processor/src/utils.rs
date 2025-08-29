use std::time::{SystemTime, UNIX_EPOCH};

pub fn current_timestamp_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64
}

pub fn add_noise(value: f64, noise_level: f64) -> f64 {
    let noise = (rand::random::<f64>() - 0.5) * 2.0 * noise_level * value;
    value + noise
}

pub fn clamp(value: f64, min: f64, max: f64) -> f64 {
    if value < min {
        min
    } else if value > max {
        max
    } else {
        value
    }
}

pub fn lerp(a: f64, b: f64, t: f64) -> f64 {
    a + (b - a) * t
}

pub fn map_range(value: f64, from_min: f64, from_max: f64, to_min: f64, to_max: f64) -> f64 {
    let normalized = (value - from_min) / (from_max - from_min);
    lerp(to_min, to_max, normalized)
}
