extends Node

@onready var input := weapon_input.new()

var hand: String

func equip(weapon: String):
	inventory.weapon.append(weapon)
	hand = weapon
	event.weapon = weapon

func unequip():
	hand = ""
	event.weapon = ""

func switch(weapon: String):
	hand = weapon
	event.weapon = weapon

func _input(event: InputEvent) -> void:
	input.handle(event)
