extends Node

@onready var local := save_local.new()

func _ready() -> void:
	add_child(local)
