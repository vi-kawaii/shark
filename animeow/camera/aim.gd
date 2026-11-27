extends Node3D

class_name camera_aim

var offset := Vector3(0.7, 0.3, 0.0)

func _process(_delta: float) -> void:
	if not camera.cam:
		return

	camera.cam.global_position += camera.cam.global_transform.basis * offset
