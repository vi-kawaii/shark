extends RefCounted

class_name inventory_weapon

signal changed

var weapons: Array[String] = []

var i: int

func append(weapon: String):
	if weapons.has(weapon):
		return

	weapons.append(weapon)
	changed.emit()

func remove(weapon: String):
	weapons.erase(weapon)
	changed.emit()

func has(weapon: String) -> bool:
	return weapons.has(weapon)

func select(number: int):
	if number > weapons.size():
		return

	return weapons[number]

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
