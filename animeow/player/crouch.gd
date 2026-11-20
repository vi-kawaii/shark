extends Resource

class_name player_crouch

@export var height_ratio := 0.5
@export var stand_camera_height := 1.6
@export var camera_height := 1.0

func get_capsule_height(default_height: float, crouching: bool) -> float:
	return default_height * (height_ratio if crouching else 1.0)

func get_camera_height(crouching: bool) -> float:
	return camera_height if crouching else stand_camera_height
