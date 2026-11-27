extends Node

var cam := Camera3D.new()

var third_person := camera_third_person.new()
var aim := camera_aim.new()

func _ready() -> void:
	add_child(third_person)
	add_child(aim)

func get_yaw_basis() -> Basis:
	return Basis(Vector3.UP, cam.rotation.y)
