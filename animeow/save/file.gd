extends Resource

class_name save_file

@export var visits: int:
	set(value):
		visits = value
		changed.emit()
