extends Node3D

func _ready():
	get_tree().set_auto_accept_quit(false)
	event.camera = camera.third_person
	loading.start(game)

func game():
	print("hi world, its shark 🦈")
	print("shark visits = ", save.local.data.visits)

	save.local.data.visits += 1

	weapon.equip("Бита")
	weapon.equip("Пистолет")
	weapon.equip("Автомат")
	weapon.equip("Винтовка")
	weapon.equip("Граната")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("bye bye")

		net.go_offline()
		save.local.write()

		get_tree().quit()

func close_game():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
