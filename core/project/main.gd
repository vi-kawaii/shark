extends Node

const default = preload("res://core/project/default.gd")

const global = preload("res://core/project/global.gd")
const path = preload("res://core/project/path.gd")

static func _static_init():
	print("Hello world")
	print("this is project {0}".format([path.get_value()]))

# static func get_save_path_for(project_name: String) -> String:
# 	return "user://{}.savedata.json".format(project_name)

# static func get_store_path_for(project_name: String) -> String:
# 	return "{}.store".format(project_name)

# static func get_project_path_for(project_name: String) -> String:
# 	return ""
