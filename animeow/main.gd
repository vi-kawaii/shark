extends Node3D

@onready var player := preload("res://me/static/player.tscn").instantiate()
@onready var level := preload("res://level/1.tscn").instantiate()
@onready var environment := preload("res://environment.tscn").instantiate()

@onready var loading := preload("res://loading.tscn").instantiate()
@onready var save := preload("res://save.gd").new()
@onready var mp := preload("res://multiplayer.gd").new()

func _ready():
	create_game()
	create_ui()

func create_game():
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

func create_ui():
	var control = Control.new()

	var panel = Panel.new()
	control.add_child(panel)

	var label = Label.new()
	label.text = "Hello World"
	panel.add_child(label)

	add_child(control)

func reload_game():
	get_tree().reload_current_scene()

func reload_ui():
	for c in get_children():
		if c is Control:
			c.queue_free()

	create_ui()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:

		if event.keycode == KEY_F5 and event.ctrl_pressed:
			reload_game()

		elif event.keycode == KEY_F5:
			reload_ui()
