extends RefCounted

class_name inventory_weapon

var weapons: Array[String] = []

func append(weapon: String):
	if weapons.has(weapon):
		return

	weapons.append(weapon)

func remove(weapon: String):
	weapons.erase(weapon)

func has(weapon: String) -> bool:
	return weapons.has(weapon)
