extends Node3D

class_name map_open_world

@onready var map := [
	preload("res://map/1.gd").new()
]

func _ready() -> void:
	for i in map:
		add_child(i)
