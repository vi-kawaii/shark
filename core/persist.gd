extends Object

const write = preload("res://core/write.gd")
const read = preload("res://core/read.gd")

static func write(project_name: String, data: Variant) -> void:
	write(project_name, data)

static func read(project_name: String, type: Variant) -> Variant:
	read(project_name, type)

static func read(project_name: String) -> Variant:
	var save_path = Project.get_save_path_for(project_name)

	if not FileAccess.file_exists(save_path):
		return {}

	var file = FileAccess.open(save_path, FileAccess.READ)

	var json_data = file.get_as_text()
	var data = JSON.parse_string(json_data)

	file.close()

	return data

static func write(project_name: String, data: Variant) -> void:
	var save_path = Project.get_save_path_for(project_name)
	var file = FileAccess.open(save_path, FileAccess.WRITE)

	var json_data = JSON.stringify(data)
	file.store_string(json_data)

	file.close()
