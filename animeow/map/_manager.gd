extends Node3D

class_name map_manager

@onready var first := map_first.new()

signal created

func _ready() -> void:
	add_child(first)
	created.emit()
