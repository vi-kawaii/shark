extends Resource

class_name camera_rotation

class camera_rotation_axis extends Resource:
	@export var target := 0.0
	@export var current := 0.0
	@export var velocity := 0.0
	@export var minimum := 0.0
	@export var maximum := 0.0

@export var yaw := camera_rotation_axis.new()
@export var pitch := camera_rotation_axis.new()

func _init() -> void:
	pitch.minimum = deg_to_rad(-70)
	pitch.maximum = deg_to_rad(60)
