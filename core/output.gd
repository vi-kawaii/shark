extends RefCounted

var lines: Array = []

func print_value(s: String) -> void:
	lines.append(s)
	print(s)

func clear() -> void:
	lines.clear()

func get_lines() -> Array:
	return lines
