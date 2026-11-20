extends Node

class_name save

const SAVE_PATH := "user://save_file.tres"

static var data: save_file

static func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = save_file.new()

	data = load(SAVE_PATH)

static func write() -> void:
	ResourceSaver.save(data, SAVE_PATH)
