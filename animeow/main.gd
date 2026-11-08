extends Node3D

@onready const player := preload("res://me/src/player.tscn").instantiate()
@onready const level := preload("res://level/1.tscn").instantiate()
@onready const environment := preload("res://environment.tscn").instantiate()

@onready const loading := preload("res://loading.tscn").instantiate()
@onready const save := preload("res://save.gd")
@onready const multiplayer := preload("res://multiplayer.gd").new()

@onready const watcher := preload("res://watcher.gd").attach(self)

func _ready() -> void:
	_build()

func _build():
	add_child(loading)

	loading.start()

	print("hi world, its shark 🦈")

	savefile = save.read()
	if savefile == null:
		savefile = SaveFile.new()
		savefile.data = {"visits": 0}
	savefile.data.visits = int(savefile.data.get("visits", 0)) + 1
	save.write(savefile)

	print("shark visits = ", savefile.data.visits)

	add_child(multiplayer)
	add_child(environment)
	add_child(level)
	add_child(player)

	player.camera_rig.camera.make_current()

	loading.finish()

	# 1. Создаст HUD, добавит его на текущую ноду (self) и вернет объект в view
	var view = ui.get_view("hud").add(self)

	# 2. Передаст состояние (внутренний метод проверит наличие поля state в GmlView)
	ui.get_view("hud").set_state({"hp": 100, "gun": 7})

	# 3. Полностью удалит HUD с экрана, сотрет его из кэша и очистит память
	# ui.get("hud").clear()

	# view.set_state({"hp": 100, "gun": 7})

	#add_child(ui.get("hud"))


func restart() -> void:
	print("[main] пересоздаю сцену")

	# сносим всех детей, кроме вотчера
	for child in get_children():
		if child == watcher:
			continue
		child.queue_free()

	await get_tree().process_frame
	await get_tree().process_frame

	_build()

	if watcher:
		watcher.reset()
