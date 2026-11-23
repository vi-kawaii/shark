extends Node3D

@onready var first := map_first.new()

func _ready() -> void:
	add_child(first)
