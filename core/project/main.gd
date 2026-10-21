extends Object

class_name Project

static func get_save_path_for(project_name: String) -> String:
	return "user://{}.savedata.json".format(project_name)

static func get_store_path_for(project_name: String) -> String:
	return "{}.store".format(project_name)

static func get_project_path_for(project_name: String) -> String:
	return ""
