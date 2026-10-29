extends Node3D

const _player := preload("res://player.tscn")
const _level := preload("res://level/1.tscn")
const _environment := preload("res://environment.tscn")
const _loading := preload("res://loading.tscn")

const _save := preload("res://save.gd")

var player
var level
var environment
var loading

var savefile

func _ready() -> void:
	loading = _loading.instantiate()
	add_child(loading)

	loading.start()

	print("hi world, its shark 🦈")

	savefile = _save.read()
	if savefile == null:
		savefile = SaveFile.new()
		savefile.data = {"visits": 0}
	savefile.data.visits = int(savefile.data.get("visits", 0)) + 1
	_save.write(savefile)

	print("shark visits = ", savefile.data.visits)

	environment = _environment.instantiate()
	add_child(environment)

	level = _level.instantiate()
	add_child(level)

	player = _player.instantiate()
	add_child(player)

	player.camera_rig.camera.make_current()

	loading.finish()
