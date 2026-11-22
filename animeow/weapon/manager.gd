extends Node

class_name weapon_manager

@onready var inventory := inventory_weapon.new()

@onready var event_global_ := event_global.get_instance()

var hand: String

func equip(weapon: String):
	inventory.append(weapon)
	hand = weapon
	emit_event(weapon)

func unequip():
	hand = ""
	emit_event("")

func switch(weapon: String):
	hand = weapon
	emit_event(weapon)

func emit_event(weapon: String):
	event_global_.weapon = weapon
	event_global_.weapon_changed.emit()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	if not event.pressed:
		return

	match event.button_index:
		MOUSE_BUTTON_LEFT:
			print("Нажата левая кнопка")

		MOUSE_BUTTON_RIGHT:
			print("Нажата правая кнопка")

	input_change_weapon(event)

func input_change_weapon(event: InputEvent):
	var weapon: String
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			weapon = inventory.next()

		MOUSE_BUTTON_WHEEL_DOWN:
			weapon = inventory.prev()

	if not weapon:
		return

	hand = weapon
	emit_event(weapon)
