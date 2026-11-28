extends Node

class_name weapon_input

func handle(e: InputEvent):
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode >= KEY_1 and e.keycode <= KEY_5:
			weapon.hand.name = inventory.weapon.select(e.keycode - KEY_1)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			weapon.fire()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT:
		camera.aim_mode = e.pressed
