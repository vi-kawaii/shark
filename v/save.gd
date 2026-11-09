extends Node

const SAVE_DIR := "user://saves/"

static func get_save_path_for() -> String:
	return SAVE_DIR.path_join("savefile.tres")

static func read() -> savefile:
	var save_path := get_save_path_for()

	if not FileAccess.file_exists(save_path):
		return null

	var res := ResourceLoader.load(save_path)
	if res is savefile:
		return res

	return null

static func write(data: Variant) -> void:
	var save_path := get_save_path_for()
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

	var save: savefile
	if data is savefile:
		save = data
	elif data is Dictionary:
		save = savefile.new()
		save.data = data
	else:
		push_error("SaveManager.write: data must be Dictionary or savefile")
		return

	var err := ResourceSaver.save(save, save_path)
	if err != OK:
		push_error("SaveManager.write failed: %s (err %d)" % [save_path, err])

# Автоопределение имени проекта: CLI-аргумент → feature tag → имя сцены → "default"
static func _default_() -> String:
	var args = OS.get_cmdline_user_args()
	if args.size() > 0:
		return args[0]

	for tag in ["animeow", "v", "shark"]:
		if OS.has_feature(tag):
			return tag

	var scene = Engine.get_main_loop().current_scene
	if scene and scene.scene_file_path:
		return scene.scene_file_path.get_file().get_basename()

	return "default"
