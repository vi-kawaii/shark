extends Node

var third_person := camera_third_person.new()

func _ready() -> void:
	add_child(third_person)
