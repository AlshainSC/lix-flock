// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits (topbar removed - not available)
// topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
// window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
// window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// 3D Visualization for drone swarm
class DroneVisualization {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId)
    this.ctx = this.canvas ? this.canvas.getContext('2d') : null
    this.drones = []
    this.animationId = null
    
    if (this.canvas) {
      this.setupCanvas()
      this.startAnimation()
    }
  }
  
  setupCanvas() {
    // Set canvas size
    this.canvas.width = this.canvas.offsetWidth
    this.canvas.height = this.canvas.offsetHeight
    
    // Handle resize
    window.addEventListener('resize', () => {
      this.canvas.width = this.canvas.offsetWidth
      this.canvas.height = this.canvas.offsetHeight
    })
  }
  
  updateDrones(droneData) {
    this.drones = droneData || []
  }
  
  draw() {
    if (!this.ctx) return
    
    const { width, height } = this.canvas
    
    // Clear canvas
    this.ctx.fillStyle = '#000000'
    this.ctx.fillRect(0, 0, width, height)
    
    // Draw grid
    this.drawGrid()
    
    // Draw drones
    this.drones.forEach(drone => this.drawDrone(drone))
    
    // Draw connections between nearby drones
    this.drawConnections()
  }
  
  drawGrid() {
    const { width, height } = this.canvas
    const gridSize = 50
    
    this.ctx.strokeStyle = '#1f2937'
    this.ctx.lineWidth = 1
    
    // Vertical lines
    for (let x = 0; x <= width; x += gridSize) {
      this.ctx.beginPath()
      this.ctx.moveTo(x, 0)
      this.ctx.lineTo(x, height)
      this.ctx.stroke()
    }
    
    // Horizontal lines
    for (let y = 0; y <= height; y += gridSize) {
      this.ctx.beginPath()
      this.ctx.moveTo(0, y)
      this.ctx.lineTo(width, y)
      this.ctx.stroke()
    }
  }
  
  drawDrone(drone) {
    if (!drone.position) return
    
    const { width, height } = this.canvas
    
    // Convert 3D position to 2D screen coordinates
    const x = (drone.position.x / 1000) * width / 2 + width / 2
    const y = (drone.position.y / 1000) * height / 2 + height / 2
    const size = Math.max(3, 8 - (drone.position.z / 100))
    
    // Draw drone
    this.ctx.fillStyle = drone.status === 'active' ? '#3b82f6' : '#ef4444'
    this.ctx.beginPath()
    this.ctx.arc(x, y, size, 0, 2 * Math.PI)
    this.ctx.fill()
    
    // Draw velocity vector
    if (drone.velocity) {
      const vx = drone.velocity.vx * 2
      const vy = drone.velocity.vy * 2
      
      this.ctx.strokeStyle = '#10b981'
      this.ctx.lineWidth = 2
      this.ctx.beginPath()
      this.ctx.moveTo(x, y)
      this.ctx.lineTo(x + vx, y + vy)
      this.ctx.stroke()
    }
    
    // Draw drone ID
    this.ctx.fillStyle = '#ffffff'
    this.ctx.font = '10px monospace'
    this.ctx.fillText(drone.id.slice(-4), x + size + 2, y - size)
  }
  
  drawConnections() {
    const connectionDistance = 100
    
    this.ctx.strokeStyle = '#374151'
    this.ctx.lineWidth = 1
    
    for (let i = 0; i < this.drones.length; i++) {
      for (let j = i + 1; j < this.drones.length; j++) {
        const drone1 = this.drones[i]
        const drone2 = this.drones[j]
        
        if (!drone1.position || !drone2.position) continue
        
        const distance = Math.sqrt(
          Math.pow(drone1.position.x - drone2.position.x, 2) +
          Math.pow(drone1.position.y - drone2.position.y, 2) +
          Math.pow(drone1.position.z - drone2.position.z, 2)
        )
        
        if (distance <= connectionDistance) {
          const { width, height } = this.canvas
          
          const x1 = (drone1.position.x / 1000) * width / 2 + width / 2
          const y1 = (drone1.position.y / 1000) * height / 2 + height / 2
          const x2 = (drone2.position.x / 1000) * width / 2 + width / 2
          const y2 = (drone2.position.y / 1000) * height / 2 + height / 2
          
          this.ctx.beginPath()
          this.ctx.moveTo(x1, y1)
          this.ctx.lineTo(x2, y2)
          this.ctx.stroke()
        }
      }
    }
  }
  
  startAnimation() {
    const animate = () => {
      this.draw()
      this.animationId = requestAnimationFrame(animate)
    }
    animate()
  }
  
  stop() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId)
    }
  }
}

// Initialize visualization when page loads
document.addEventListener('DOMContentLoaded', () => {
  window.droneViz = new DroneVisualization('swarm-canvas')
})

// Listen for drone position updates from LiveView
window.addEventListener('phx:drone-positions', (e) => {
  if (window.droneViz) {
    window.droneViz.updateDrones(e.detail.drones)
  }
})
