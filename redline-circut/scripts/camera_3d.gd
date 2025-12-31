extends Camera3D

@export var target: Node3D  # Assign your car in inspector
@export var offset = Vector3(0, 3, 8)  # Behind and above
@export var smoothness = 5.0

func _physics_process(delta):
	if target:
		var target_pos = target.global_position + offset
		global_position = global_position.lerp(target_pos, smoothness * delta)
		look_at(target.global_position, Vector3.UP)
