extends RefCounted

class_name inventory_weapon

var weapons: Array[String] = []

var i: int

func append(weapon: String):
	if weapons.has(weapon):
		return

	weapons.append(weapon)

func remove(weapon: String):
	weapons.erase(weapon)

func has(weapon: String) -> bool:
	return weapons.has(weapon)

func next() -> String:
	i += 1
	wrapi_()
	return weapons[i]

func prev() -> String:
	i -= 1
	wrapi_()
	return weapons[i]

func wrapi_():
	i = wrapi(i, 0, weapons.size())
