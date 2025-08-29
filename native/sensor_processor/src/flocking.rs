use serde::{Deserialize, Serialize};
use rustler::NifStruct;
use nalgebra::{Vector3, Point3};
use crate::{DroneState, DronePosition, DroneVelocity};

#[derive(Debug, Clone, Serialize, Deserialize, NifStruct)]
#[module = "FlockingParams"]
pub struct FlockingParams {
    pub neighbor_radius: f64,
    pub separation_radius: f64,
    pub max_speed: f64,
    pub max_force: f64,
    pub separation_weight: f64,
    pub alignment_weight: f64,
    pub cohesion_weight: f64,
    pub obstacle_avoidance_weight: f64,
}

impl Default for FlockingParams {
    fn default() -> Self {
        Self {
            neighbor_radius: 100.0,
            separation_radius: 50.0,
            max_speed: 50.0,
            max_force: 10.0,
            separation_weight: 2.0,
            alignment_weight: 1.0,
            cohesion_weight: 1.0,
            obstacle_avoidance_weight: 3.0,
        }
    }
}

#[derive(Debug, Clone)]
pub struct Vector3D {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

impl Vector3D {
    pub fn new(x: f64, y: f64, z: f64) -> Self {
        Self { x, y, z }
    }
    
    pub fn zero() -> Self {
        Self::new(0.0, 0.0, 0.0)
    }
    
    pub fn magnitude(&self) -> f64 {
        (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
    }
    
    pub fn normalize(&self) -> Self {
        let mag = self.magnitude();
        if mag > 0.0 {
            Self::new(self.x / mag, self.y / mag, self.z / mag)
        } else {
            Self::zero()
        }
    }
    
    pub fn limit(&self, max_magnitude: f64) -> Self {
        let mag = self.magnitude();
        if mag > max_magnitude {
            let scale = max_magnitude / mag;
            Self::new(self.x * scale, self.y * scale, self.z * scale)
        } else {
            self.clone()
        }
    }
    
    pub fn add(&self, other: &Self) -> Self {
        Self::new(self.x + other.x, self.y + other.y, self.z + other.z)
    }
    
    pub fn subtract(&self, other: &Self) -> Self {
        Self::new(self.x - other.x, self.y - other.y, self.z - other.z)
    }
    
    pub fn multiply(&self, scalar: f64) -> Self {
        Self::new(self.x * scalar, self.y * scalar, self.z * scalar)
    }
    
    pub fn distance_to(&self, other: &Self) -> f64 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        let dz = self.z - other.z;
        (dx * dx + dy * dy + dz * dz).sqrt()
    }
}

impl From<DronePosition> for Vector3D {
    fn from(pos: DronePosition) -> Self {
        Self::new(pos.x, pos.y, pos.z)
    }
}

impl From<DroneVelocity> for Vector3D {
    fn from(vel: DroneVelocity) -> Self {
        Self::new(vel.vx, vel.vy, vel.vz)
    }
}

pub fn calculate_boids_forces(
    drone: &DroneState,
    neighbors: &[DroneState],
    params: &FlockingParams,
) -> Vector3D {
    let position = Vector3D::from(drone.position.clone());
    let velocity = Vector3D::from(drone.velocity.clone());
    
    // Find neighbors within range
    let nearby_neighbors: Vec<&DroneState> = neighbors
        .iter()
        .filter(|neighbor| {
            let neighbor_pos = Vector3D::from(neighbor.position.clone());
            position.distance_to(&neighbor_pos) <= params.neighbor_radius
        })
        .collect();
    
    // Calculate individual forces
    let separation = calculate_separation(&position, &nearby_neighbors, params);
    let alignment = calculate_alignment(&velocity, &nearby_neighbors, params);
    let cohesion = calculate_cohesion(&position, &nearby_neighbors, params);
    
    // Combine forces with weights
    let total_force = separation
        .multiply(params.separation_weight)
        .add(&alignment.multiply(params.alignment_weight))
        .add(&cohesion.multiply(params.cohesion_weight));
    
    // Apply force limits
    total_force.limit(params.max_force)
}

fn calculate_separation(
    position: &Vector3D,
    neighbors: &[&DroneState],
    params: &FlockingParams,
) -> Vector3D {
    let mut separation_force = Vector3D::zero();
    let mut count = 0;
    
    for neighbor in neighbors {
        let neighbor_pos = Vector3D::from(neighbor.position.clone());
        let distance = position.distance_to(&neighbor_pos);
        
        if distance > 0.0 && distance < params.separation_radius {
            // Calculate vector pointing away from neighbor
            let diff = position.subtract(&neighbor_pos);
            let normalized_diff = diff.normalize();
            
            // Weight by inverse distance (closer = stronger repulsion)
            let weighted_diff = normalized_diff.multiply(1.0 / distance);
            separation_force = separation_force.add(&weighted_diff);
            count += 1;
        }
    }
    
    if count > 0 {
        // Average the separation forces
        separation_force = separation_force.multiply(1.0 / count as f64);
        
        // Normalize to get desired direction
        if separation_force.magnitude() > 0.0 {
            separation_force.normalize()
        } else {
            Vector3D::zero()
        }
    } else {
        Vector3D::zero()
    }
}

fn calculate_alignment(
    velocity: &Vector3D,
    neighbors: &[&DroneState],
    _params: &FlockingParams,
) -> Vector3D {
    if neighbors.is_empty() {
        return Vector3D::zero();
    }
    
    // Calculate average velocity of neighbors
    let mut avg_velocity = Vector3D::zero();
    
    for neighbor in neighbors {
        let neighbor_vel = Vector3D::from(neighbor.velocity.clone());
        avg_velocity = avg_velocity.add(&neighbor_vel);
    }
    
    avg_velocity = avg_velocity.multiply(1.0 / neighbors.len() as f64);
    
    // Calculate desired velocity change
    let desired_velocity = avg_velocity.normalize();
    let current_velocity = velocity.normalize();
    
    desired_velocity.subtract(&current_velocity)
}

fn calculate_cohesion(
    position: &Vector3D,
    neighbors: &[&DroneState],
    _params: &FlockingParams,
) -> Vector3D {
    if neighbors.is_empty() {
        return Vector3D::zero();
    }
    
    // Calculate center of mass of neighbors
    let mut center_of_mass = Vector3D::zero();
    
    for neighbor in neighbors {
        let neighbor_pos = Vector3D::from(neighbor.position.clone());
        center_of_mass = center_of_mass.add(&neighbor_pos);
    }
    
    center_of_mass = center_of_mass.multiply(1.0 / neighbors.len() as f64);
    
    // Calculate desired direction toward center of mass
    let desired_direction = center_of_mass.subtract(position);
    
    if desired_direction.magnitude() > 0.0 {
        desired_direction.normalize()
    } else {
        Vector3D::zero()
    }
}

pub fn apply_boundary_forces(
    position: &Vector3D,
    velocity: &Vector3D,
    world_bounds: (f64, f64, f64),
    boundary_margin: f64,
) -> Vector3D {
    let (x_bound, y_bound, z_bound) = world_bounds;
    let mut boundary_force = Vector3D::zero();
    
    // X boundaries
    if position.x < -x_bound/2.0 + boundary_margin {
        boundary_force.x += ((-x_bound/2.0 + boundary_margin) - position.x) * 0.1;
    } else if position.x > x_bound/2.0 - boundary_margin {
        boundary_force.x -= (position.x - (x_bound/2.0 - boundary_margin)) * 0.1;
    }
    
    // Y boundaries
    if position.y < -y_bound/2.0 + boundary_margin {
        boundary_force.y += ((-y_bound/2.0 + boundary_margin) - position.y) * 0.1;
    } else if position.y > y_bound/2.0 - boundary_margin {
        boundary_force.y -= (position.y - (y_bound/2.0 - boundary_margin)) * 0.1;
    }
    
    // Z boundaries (ground and ceiling)
    if position.z < boundary_margin {
        boundary_force.z += (boundary_margin - position.z) * 0.2;
    } else if position.z > z_bound - boundary_margin {
        boundary_force.z -= (position.z - (z_bound - boundary_margin)) * 0.1;
    }
    
    boundary_force
}

pub fn calculate_obstacle_avoidance(
    position: &Vector3D,
    velocity: &Vector3D,
    obstacles: &[(f64, f64, f64, f64)], // (x, y, z, radius)
    avoidance_distance: f64,
) -> Vector3D {
    let mut avoidance_force = Vector3D::zero();
    
    for &(ox, oy, oz, radius) in obstacles {
        let obstacle_pos = Vector3D::new(ox, oy, oz);
        let distance = position.distance_to(&obstacle_pos);
        let danger_distance = radius + avoidance_distance;
        
        if distance < danger_distance && distance > 0.0 {
            // Calculate avoidance vector
            let avoidance_dir = position.subtract(&obstacle_pos).normalize();
            
            // Strength inversely proportional to distance
            let strength = (danger_distance - distance) / danger_distance;
            let weighted_avoidance = avoidance_dir.multiply(strength * 2.0);
            
            avoidance_force = avoidance_force.add(&weighted_avoidance);
        }
    }
    
    avoidance_force
}

pub fn integrate_motion(
    position: &Vector3D,
    velocity: &Vector3D,
    acceleration: &Vector3D,
    dt: f64,
    max_speed: f64,
) -> (Vector3D, Vector3D) {
    // Update velocity with acceleration
    let new_velocity = velocity.add(&acceleration.multiply(dt));
    let limited_velocity = new_velocity.limit(max_speed);
    
    // Update position with velocity
    let new_position = position.add(&limited_velocity.multiply(dt));
    
    (new_position, limited_velocity)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_vector3d_operations() {
        let v1 = Vector3D::new(1.0, 2.0, 3.0);
        let v2 = Vector3D::new(4.0, 5.0, 6.0);
        
        let sum = v1.add(&v2);
        assert_eq!(sum.x, 5.0);
        assert_eq!(sum.y, 7.0);
        assert_eq!(sum.z, 9.0);
        
        let magnitude = v1.magnitude();
        assert!((magnitude - 3.7416573868).abs() < 1e-6);
    }
    
    #[test]
    fn test_separation_force() {
        let position = Vector3D::new(0.0, 0.0, 0.0);
        let neighbor = DroneState {
            id: "test".to_string(),
            position: DronePosition { x: 10.0, y: 0.0, z: 0.0 },
            velocity: DroneVelocity { vx: 0.0, vy: 0.0, vz: 0.0 },
            timestamp: 0,
        };
        
        let neighbors = vec![&neighbor];
        let params = FlockingParams::default();
        
        let force = calculate_separation(&position, &neighbors, &params);
        
        // Should point away from neighbor (negative x direction)
        assert!(force.x < 0.0);
        assert!(force.magnitude() > 0.0);
    }
}
