extends Node

var hud := ui_hud.new()
var crosshair := ui_crosshair.new()

func _ready() -> void:
	add_child(hud)
	add_child(crosshair)
