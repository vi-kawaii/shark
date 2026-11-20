extends Node

class_name save_local

const SAVE_PATH := "user://save_file.tres"

var data: save_file

func _ready() -> void:
	read()
	data.changed.connect(write)

func read() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = save_file.new()

	data = load(SAVE_PATH)

func write() -> void:
	ResourceSaver.save(data, SAVE_PATH)
