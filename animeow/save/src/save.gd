extends Node

const SAVE_PATH := "user://savefile.tres"

func read() -> save_file:
	if not FileAccess.file_exists(SAVE_PATH):
		return null

	var res := ResourceLoader.load(SAVE_PATH)
	if res is save_file:
		return res

	return null

func write(data: Variant) -> void:
	var save: save_file
	if data is save_file:
		save = data
	elif data is Dictionary:
		save = save_file.new()
		save.data = data
	else:
		push_error("SaveManager.write: data must be Dictionary or savefile")
		return

	var err := ResourceSaver.save(save, SAVE_PATH)
	if err != OK:
		push_error("SaveManager.write failed: %s (err %d)" % [SAVE_PATH, err])
