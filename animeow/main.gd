extends Node3D

@onready var nodes := {
	level = preload("res://level/1.tscn").instantiate(),
}

@onready var p := player.new()
@onready var mp := multiplayer_default.new()
@onready var ls := loading_screen.new()
@onready var lm := loading_manager.get_instance()
@onready var env := environment_default.new()

func _ready():
	get_tree().set_auto_accept_quit(false)

	for n in nodes.values():
		add_child(n)

	add_child(env)
	add_child(p)
	add_child(ls)
	add_child(lm)
	add_child(mp)

	lm.start_loading(game)

func game():
	save.load()
	save.data.visits += 1
	save.write()

	print("hi world, its shark 🦈")
	print("shark visits = ", save.data.visits)

	p.camera_rig.camera.make_current()

	var theme := Theme.new()

	theme.set_color("font_outline_color", "Label", Color.BLACK)
	theme.set_constant("outline_size", "Label", 4)

	var control = Control.new()
	control.theme = theme
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ЛЕВЫЙ НИЖНИЙ УГОЛ - здоровье и броня
	var stats_box = VBoxContainer.new()
	stats_box.anchor_left = 0.0
	stats_box.anchor_top = 1.0
	stats_box.anchor_bottom = 1.0
	stats_box.offset_left = 10
	stats_box.offset_top = -60

	var health_label = Label.new()
	health_label.text = "Здоровье: 100%"
	stats_box.add_child(health_label)

	var armor_label = Label.new()
	armor_label.text = "Броня: 100%"
	stats_box.add_child(armor_label)

	control.add_child(stats_box)

	# ПРАВЫЙ ВЕРХНИЙ УГОЛ - карта
	var map_label = Label.new()
	map_label.text = "Карта"
	map_label.anchor_left = 1.0
	map_label.anchor_right = 1.0
	map_label.anchor_top = 0.0
	map_label.offset_left = -60
	map_label.offset_top = 10
	control.add_child(map_label)

	# ПРАВЫЙ НИЖНИЙ УГОЛ - оружие и патроны
	var weapon_box = VBoxContainer.new()
	weapon_box.anchor_left = 1.0
	weapon_box.anchor_right = 1.0
	weapon_box.anchor_top = 1.0
	weapon_box.anchor_bottom = 1.0
	weapon_box.offset_left = -200
	weapon_box.offset_right = -10
	weapon_box.offset_top = -60

	var weapon_label = Label.new()
	weapon_label.text = "Оружие: АК-47"
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_box.add_child(weapon_label)

	var ammo_label = Label.new()
	ammo_label.text = "Патроны: 30 / 120"
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_box.add_child(ammo_label)

	control.add_child(weapon_box)

	add_child(control)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("bye bye")
		mp.go_offline()

		get_tree().quit()

func close_game():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
