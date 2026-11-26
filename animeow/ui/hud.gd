extends Control

class_name ui_hud

var weapon_box: VBoxContainer

func _ready():
	weapon.hand.changed.connect(update_weapon)
	inventory.weapon.changed.connect(update_labels)

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	add_child(stats_box)

	# ПРАВЫЙ ВЕРХНИЙ УГОЛ - карта
	var map_label = Label.new()
	map_label.text = "Карта"
	map_label.anchor_left = 1.0
	map_label.anchor_right = 1.0
	map_label.anchor_top = 0.0
	map_label.offset_left = -60
	map_label.offset_top = 10
	add_child(map_label)

	# ПРАВЫЙ НИЖНИЙ УГОЛ - оружие и патроны
	weapon_box = VBoxContainer.new()
	weapon_box.anchor_left = 1.0
	weapon_box.anchor_right = 1.0
	weapon_box.anchor_top = 1.0
	weapon_box.anchor_bottom = 1.0
	weapon_box.offset_left = -200
	weapon_box.offset_right = -10
	weapon_box.offset_top = -10
	weapon_box.offset_bottom = -10
	# Заставляем контейнер автоматически расти вверх при добавлении новых строк:
	weapon_box.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var ammo_label = Label.new()
	ammo_label.text = "Патроны: 30 / 120"
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_box.add_child(ammo_label)

	add_child(weapon_box)

func add_weapon(title: String) -> Label:
	var l = Label.new()
	l.text = title
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	#weapon_labels.append(l)

	return l

func update_weapon():
	for w in weapon_box.get_children():
		var clean_name = w.text.replace("[", "").replace("]", "")
		if clean_name == weapon.hand.name:
			w.text = "[{0}]".format([clean_name])
		else:
			w.text = clean_name

func update_labels():
	for w: Label in weapon_box.get_children():
		w.queue_free()

	for w: String in inventory.weapon.weapons:
		var l := add_weapon(w)
		weapon_box.add_child(l)

	update_weapon()
