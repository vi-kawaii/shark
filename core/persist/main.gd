extends Object

const write = preload("res://core/persist/write.gd")
const read = preload("res://core/persist/read.gd")

static func write(project_name: String, data: Variant) -> void:
	write(project_name, data)

static func read(project_name: String, type: Variant) -> Variant:
	read(project_name, type)
