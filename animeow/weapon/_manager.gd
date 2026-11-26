extends Node

@onready var input := weapon_input.new()

var shoot := weapon_shoot.new()

var hand: weapon_file

func _ready() -> void:
	hand = weapon_file.new()

func equip(weapon: String):
	inventory.weapon.append(weapon)
	hand.name = weapon

func unequip():
	hand = null

func switch(weapon: weapon_file):
	hand = weapon

func _input(event: InputEvent) -> void:
	input.handle(event)

func fire():
	shoot.fire()
