extends Node

@onready var hud := ui_hud.new()

func _ready() -> void:
	add_child(hud)
