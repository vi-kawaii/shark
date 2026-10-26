extends Object

const move = preload("res://player/move/main.gd")
const state = preload("res://player/state/main.gd")

static func update(
	player: CharacterBody3D,
	camera_rig: Node3D,
	is_crouching: bool,
	walk_speed: float, run_speed: float, crouch_speed: float,
	acceleration: float, air_acceleration: float, friction: float,
	delta: float
) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (camera_rig.get_yaw_basis() * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0.1:
		var speed := state.get_speed(
			is_crouching,
			Input.is_action_pressed("sprint"),
			walk_speed, run_speed, crouch_speed
		)
		var accel := acceleration if player.is_on_floor() else air_acceleration
		player.velocity = move.apply_horizontal(player.velocity, direction, speed, accel, delta)
	elif player.is_on_floor():
		player.velocity = move.apply_friction(player.velocity, friction, delta)
