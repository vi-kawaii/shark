extends Object

static func read(project_name: String) -> Variant:
	var save_path = Project.get_save_path_for(project_name)

	if not FileAccess.file_exists(save_path):
		return {}

	var file = FileAccess.open(save_path, FileAccess.READ)

	var json_data = file.get_as_text()
	var data = JSON.parse_string(json_data)

	file.close()

	return data
