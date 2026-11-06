extends Node3D

const _player := preload("res://player.tscn")
const _level := preload("res://level/1.tscn")
const _environment := preload("res://environment.tscn")
const _loading := preload("res://loading.tscn")

const _save := preload("res://save.gd")

const _multiplayer := preload("res://multiplayer.gd")

const _watcher := preload("res://watcher.gd")

var player
var level
var environment
var loading

var savefile

var mp

var _watcher_instance: Node


func _ready() -> void:
	_build()
	_watcher_instance = _watcher.attach(self)


func _build() -> void:
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

	mp = _multiplayer.new()
	add_child(mp)

	environment = _environment.instantiate()
	add_child(environment)

	level = _level.instantiate()
	add_child(level)

	player = _player.instantiate()
	add_child(player)

	player.camera_rig.camera.make_current()

	loading.finish()

	

	view.set_state({"hp": 100, "gun": 7})

	add_child(ui.get("hud"))


func restart() -> void:
	print("[main] пересоздаю сцену")

	# сносим всех детей, кроме вотчера
	for child in get_children():
		if child == _watcher_instance:
			continue
		child.queue_free()

	await get_tree().process_frame
	await get_tree().process_frame

	_build()

	if _watcher_instance:
		_watcher_instance.reset()
