extends Object

static func write(project_name: String, data: Variant) -> void:
	var save_path = Project.get_save_path_for(project_name)
	var file = FileAccess.open(save_path, FileAccess.WRITE)

	var json_data = JSON.stringify(data)
	file.store_string(json_data)

	file.close()
