extends Node

class_name weapon_input

func handle(e: InputEvent):
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode >= KEY_1 and e.keycode <= KEY_5:
			weapon.hand.name = inventory.weapon.select(e.keycode - KEY_1)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT:
			weapon.fire()
