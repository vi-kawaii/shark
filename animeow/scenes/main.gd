extends Node3D

const WORLD_SCENE := preload("res://scenes/world/main.tscn")
const PLAYER_SCENE := preload("res://player/main.tscn")
const LEVEL_SCENE := preload("res://scenes/world/level_1/main.tscn")

const _save := preload("res://core/savemanager.gd")

var savefile
var world
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

	world = WORLD_SCENE.instantiate()
	add_child(world)

	level = LEVEL_SCENE.instantiate()
	world.add_child(level)

	player = PLAYER_SCENE.instantiate()
	world.add_child(player)

	player.camera_rig.camera.make_current()
