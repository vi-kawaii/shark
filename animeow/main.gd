extends Node3D

@onready var save := save_local.new()
@onready var multiplayer_ := multiplayer_default.new()

@onready var environment := environment_default.new()
@onready var map := map_open_world.new()

@onready var player := player_default.new()
@onready var camera_rig := camera_third_person.new()

@onready var loading_screen := loading_screen_default.new()
@onready var loading_manager_ := loading_manager.get_instance()

@onready var hud := hud_default.new()

func _ready():
	get_tree().set_auto_accept_quit(false)

	add_child(environment)
	add_child(save)

	add_child(player)
	event.camera_rig = camera_rig

	add_child(loading_screen)
	add_child(loading_manager_)

	add_child(multiplayer_)
	add_child(map)

	add_child(hud)

	loading_manager_.start_loading(game)

func game():
	print("hi world, its shark 🦈")
	print("shark visits = ", save.data.visits)

	save.data.visits += 1

	weapon.equip("Бита")
	weapon.equip("Пистолет")
	weapon.equip("Автомат")
	weapon.equip("Винтовка")
	weapon.equip("Граната")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("bye bye")

		multiplayer_.go_offline()
		save.write()

		get_tree().quit()

func close_game():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
