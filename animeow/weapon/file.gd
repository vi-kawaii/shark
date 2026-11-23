extends Resource

class_name weapon_file

@export var name: String:
	set(x):
		name = x
		changed.emit()
