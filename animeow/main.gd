extends Node3D

@onready var player := preload("res://me/static/player.tscn").instantiate()
@onready var level := preload("res://level/1.tscn").instantiate()
@onready var environment := preload("res://environment.tscn").instantiate()

@onready var loading := preload("res://loading.tscn").instantiate()
@onready var save := preload("res://save.gd").new()
@onready var mp := preload("res://multiplayer.gd").new()

@onready var watcher := preload("res://watcher.gd").attach(self)

func _ready() -> void:
	_build()

func _build():
	add_child(loading)

	loading.start()

	print("hi world, its shark 🦈")

	var s = save.read()
	if s == null:
		s = savefile.new()
		s.data = {"visits": 0}
	s.data.visits = int(s.data.get("visits", 0)) + 1
	save.write(s)

	print("shark visits = ", s.data.visits)

	add_child(mp)
	add_child(environment)
	add_child(level)
	add_child(player)

	player.camera_rig.camera.make_current()

	loading.finish()

	# 1. Создаст HUD, добавит его на текущую ноду (self) и вернет объект в view
	ui.get_view("hud").add(self)

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
