extends Node3D

@onready var nodes := {
	save = preload("res://save/local.gd").new(),
	loading = preload("res://loading.tscn").instantiate(),

	mp = preload("res://multiplayer.gd").new(),
	environment = preload("res://environment.tscn").instantiate(),
	level = preload("res://level/1.tscn").instantiate(),

	player = preload("res://me/player.gd").new(),
}

func _ready():
	for n in nodes.values():
		add_child(n)

	get_tree().set_auto_accept_quit(false)

	nodes.loading.start()

	print("hi world, its shark 🦈")

	var s = nodes.save.read()
	if s == null:
		s = save_file.new()
		s.data = {"visits": 0}
	s.data.visits = int(s.data.get("visits", 0)) + 1
	nodes.save.write(s)

	print("shark visits = ", s.data.visits)

	nodes.player.camera_rig.camera.make_current()

	nodes.loading.finish()

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
		nodes.mp.go_offline()

		get_tree().quit()

func close_game():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
