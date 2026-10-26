extends Object

const move = preload("res://player/move/main.gd")

static func update(
	player: CharacterBody3D,
	gravity: float,
	jump_velocity: float,
	is_crouching: bool,
	delta: float
) -> void:
	if not player.is_on_floor():
		player.velocity = move.apply_gravity(player.velocity, gravity, delta)
	elif Input.is_action_just_pressed("jump") and not is_crouching:
		player.velocity.y = jump_velocity
