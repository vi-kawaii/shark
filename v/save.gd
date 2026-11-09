extends Node

const SAVE_PATH := "user://savefile.tres"

func read() -> savefile:
	if not FileAccess.file_exists(SAVE_PATH):
		return null

	var res := ResourceLoader.load(SAVE_PATH)
	if res is savefile:
		return res

	return null

func write(data: Variant) -> void:
	var save: savefile
	if data is savefile:
		save = data
	elif data is Dictionary:
		save = savefile.new()
		save.data = data
	else:
		push_error("SaveManager.write: data must be Dictionary or savefile")
		return

	var err := ResourceSaver.save(save, SAVE_PATH)
	if err != OK:
		push_error("SaveManager.write failed: %s (err %d)" % [SAVE_PATH, err])
