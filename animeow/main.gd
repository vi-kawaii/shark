extends Node3D

const _player := preload("res://player.tscn")
const _level := preload("res://level/1.tscn")
const _save := preload("res://save.gd")

var savefile
var player
var level

func _ready() -> void:
	print("hi world, its shark 🦈")

	savefile = _save.read()
	if savefile == null:
		savefile = SaveFile.new()
		savefile.data = {"visits": 0}
	savefile.data.visits = int(savefile.data.get("visits", 0)) + 1
	_save.write(savefile)

	print("shark visits = ", savefile.data.visits)

	level = _level.instantiate()
	add_child(level)

	player = _player.instantiate()
	add_child(player)

	player.camera_rig.camera.make_current()
