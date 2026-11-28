extends Node

var cam := Camera3D.new()

var third_person := camera_third_person.new()
var aim := camera_aim.new()

signal aiming

var aim_mode: bool:
	set(x):
		aim_mode = x
		aiming.emit()

func _ready() -> void:
	add_child(third_person)
	add_child(aim)

	aiming.connect(handle_aim_zoom)

func get_yaw_basis() -> Basis:
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return Basis.IDENTITY
	return Basis.looking_at(forward.normalized(), Vector3.UP)

func handle_aim_zoom() -> void:
	if aim_mode:
		aim.zoom()
	else:
		aim.unzoom()
