extends Node

class_name weapon_input

func handle(e: InputEvent):
	if e is InputEventMouseButton and e.pressed:
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				weapon.hand.name = inventory.weapon.next()
			MOUSE_BUTTON_WHEEL_DOWN:
				weapon.hand.name = inventory.weapon.prev()
