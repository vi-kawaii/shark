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
