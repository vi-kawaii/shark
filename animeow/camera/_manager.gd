extends Node

var third_person := camera_third_person.new()

var offset := Vector3(0.7, 0.3, 0.0)
var cam: Camera3D

func _ready() -> void:
	add_child(third_person)
	cam = third_person.cam

func _process(_delta: float) -> void:
	if not cam:
		return

	cam.global_position = cam.global_position + cam.global_transform.basis * offset
