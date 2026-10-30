extends Control

const _control_panel = preload("res://control_panel.tscn")
const _preview = preload("res://preview.tscn")

const _save = preload("res://save.gd")

var control_panel
var preview
var save

func _ready():
	print("hi world, its shark 🦈")

	save = _save.read()
	if save == null:
		save = SaveFile.new()
		save.data = {"visits": 0}
	save.data.visits = int(save.data.get("visits", 0)) + 1
	_save.write(save)

	print("shark visits = ", save.data.visits)

	preview = _preview.instantiate()
	add_child(preview)

	control_panel = _control_panel.instantiate()
	add_child(control_panel)
