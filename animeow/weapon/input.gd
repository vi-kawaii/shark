extends Node

class_name weapon_input

func handle(e: InputEvent):
	if e is InputEventMouseButton and e.pressed:
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				var x = inventory.weapon.next()
				weapon.hand = x
				event.weapon = x
			MOUSE_BUTTON_WHEEL_DOWN:
				var x = inventory.weapon.prev()
				weapon.hand = x
				event.weapon = x
