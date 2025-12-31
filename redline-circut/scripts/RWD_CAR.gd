extends VehicleBody3D

# Vehicle Stats - Tweak these for different car feels
@export var max_engine_force = 200.0
@export var max_brake_force = 8.0
@export var max_steer_angle = 0.5  # In radians, ~28 degrees
@export var steer_speed = 3.0  # How fast steering responds

# Arcade helpers
@export var drift_factor = 0.8  # Lower = more drift (0.5-0.9 range)
@export var traction_control = 0.95  # Helps with grip (0.9-1.0 range)
@export var downforce_multiplier = 2.0  # More = sticks to ground better at speed

# Internal variables
var current_steer = 0.0
var engine_force_value = 0.0
var brake_force_value = 0.0

# Wheel references (assign these in the inspector or setup)
@onready var wheels = [
	$FrontLeftWheel,
	$FrontRightWheel,
	$RearLeftWheel,
	$RearRightWheel
]

func _ready():
	# Set up basic physics properties
	mass = 1200.0  # kg, typical car weight
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.3, 0)  # Lower center of mass for stability

func _physics_process(delta):
	# Get input
	var throttle = Input.get_axis("brake", "accelerate")  # Forward/Backward
	var steer_input = Input.get_axis("steer_right", "steer_left")
	var handbrake = Input.is_action_pressed("handbrake")
	
	# Smooth steering
	var target_steer = steer_input * max_steer_angle
	current_steer = lerp(current_steer, target_steer, steer_speed * delta)
	
	# Apply steering to front wheels
	steering = current_steer
	
	# Engine force
	if throttle > 0:
		engine_force_value = throttle * max_engine_force
		brake_force_value = 0.0
	elif throttle < 0:
		# Reverse or brake
		if linear_velocity.length() > 1.0:
			# Moving forward, apply brakes
			engine_force_value = 0.0
			brake_force_value = abs(throttle) * max_brake_force * 2.0
		else:
			# Stopped or moving slow, allow reverse
			engine_force_value = throttle * max_engine_force * 0.5  # Reverse slower
			brake_force_value = 0.0
	else:
		# Coast
		engine_force_value = 0.0
		brake_force_value = 0.5  # Light engine braking
	
	# Handbrake
	if handbrake:
		brake_force_value = max_brake_force * 1.5
		# Reduce rear wheel friction for drifting
		if wheels.size() >= 4:
			wheels[2].wheel_friction_slip = drift_factor * 0.7
			wheels[3].wheel_friction_slip = drift_factor * 0.7
	else:
		# Normal friction
		for wheel in wheels:
			wheel.wheel_friction_slip = traction_control
	
	# Apply forces
	engine_force = engine_force_value
	brake = brake_force_value
	
	# Arcade downforce (more grip at higher speeds)
	var speed = linear_velocity.length()
	var downforce = speed * downforce_multiplier
	apply_central_force(Vector3.DOWN * downforce)
	
	# Anti-roll/flip prevention (keeps car upright)
	var up = global_transform.basis.y
	var angle = up.angle_to(Vector3.UP)
	if angle > 0.5:  # If tilted more than ~30 degrees
		var correction = up.cross(Vector3.UP) * 50.0
		apply_torque(correction)

# Helper function to get current speed in km/h
func get_speed_kmh() -> float:
	return linear_velocity.length() * 3.6

# Helper to check if car is drifting
func is_drifting() -> bool:
	var forward = -global_transform.basis.z
	var velocity_dir = linear_velocity.normalized()
	var angle = forward.angle_to(velocity_dir)
	return angle > 0.3 and linear_velocity.length() > 5.0  # ~18 km/h
