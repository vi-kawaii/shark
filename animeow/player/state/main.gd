extends RefCounted

static func get_speed(
	crouching: bool,
	sprinting: bool,
	walk: float,
	run: float,
	crouch: float
) -> float:
	if crouching:
		return crouch
	if sprinting:
		return run
	return walk

static func get_capsule_height(default_height: float, crouching: bool, ratio: float) -> float:
	return default_height * (ratio if crouching else 1.0)

static func get_camera_height(stand: float, crouch: float, crouching: bool) -> float:
	return crouch if crouching else stand
