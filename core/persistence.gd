extends RefCounted

class_name Persistence

static func save(project_name: String, data: Variant) -> void:
	var save_path = Project.get_save_path_for(project_name)
	var file = FileAccess.open(save_path, FileAccess.WRITE)

	var json_data = JSON.stringify(data)
	file.store_string(json_data)

	file.close()

static func load(project_name: String, type: Variant) -> Variant:
	var save_path = Project.get_save_path_for(project_name)

	if not FileAccess.file_exists(save_path):
		return type.new()

	var file = FileAccess.open(save_path, FileAccess.READ)

	var json_data = file.get_as_text()
	var data = JSON.parse_string(json_data)

	file.close()

	return data
