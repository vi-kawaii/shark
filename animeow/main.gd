extends Node3D

@onready var map := map_manager.new()
@onready var player := player_manager.new()

func _ready():
	get_tree().set_auto_accept_quit(false)
	loading.start(game)

func game():
	print("hi world, its shark 🦈")
	print("shark visits = ", save.local.data.visits)

	save.local.data.visits += 1

	weapon.equip("1. Бита")
	weapon.equip("2. Пистолет")
	weapon.equip("3. Автомат")
	weapon.equip("4. Винтовка")
	weapon.equip("5. Граната")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("bye bye")

		net.go_offline()
		save.local.write()

		get_tree().quit()

func close_game():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
