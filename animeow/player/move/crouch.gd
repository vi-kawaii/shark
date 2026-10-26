extends Object

const state = preload("res://player/state/main.gd")

static func update(
	player: CharacterBody3D,
	want_crouch: bool,
	capsule: CapsuleShape3D,
	camera_rig: Node3D,
	default_height: float,
	crouch_ratio: float,
	stand_cam_height: float,
	crouch_cam_height: float
) -> bool:
	if want_crouch == player.get_meta("is_crouching", false):
		return false

	player.set_meta("is_crouching", want_crouch)
	capsule.height = state.get_capsule_height(default_height, want_crouch, crouch_ratio)
	camera_rig.position.y = state.get_camera_height(stand_cam_height, crouch_cam_height, want_crouch)
	return true
