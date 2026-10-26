extends Object

const SAVE_DIR := "user://saves/"

static func _sanitize(name: String) -> String:
	var result := ""
	for c in name:
		if c.is_valid_identifier() or c == "-" or c == "_":
			result += c
		else:
			result += "_"
	return result

static func _hash_name(name: String) -> String:
	# стабильный хэш, не зависящий от запуска
	return str(name.hash())

static func get_save_path_for(project_name: String) -> String:
	var safe := _sanitize(project_name)
	var hashed := _hash_name(project_name)
	return SAVE_DIR.path_join("%s_%s.tres" % [safe, hashed])

static func read(project_name: String = "") -> SaveFile:
	if project_name.is_empty():
		project_name = _default_project_name()

	var save_path := get_save_path_for(project_name)

	if not FileAccess.file_exists(save_path):
		return null

	var res := ResourceLoader.load(save_path)
	if res is SaveFile:
		return res

	return null

static func write(data: Variant, project_name: String = "") -> void:
	if project_name.is_empty():
		project_name = _default_project_name()

	var save_path := get_save_path_for(project_name)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

	var save: SaveFile
	if data is SaveFile:
		save = data
	elif data is Dictionary:
		save = SaveFile.new()
		save.data = data
	else:
		push_error("SaveManager.write: data must be Dictionary or SaveFile")
		return

	var err := ResourceSaver.save(save, save_path)
	if err != OK:
		push_error("SaveManager.write failed: %s (err %d)" % [save_path, err])

# Автоопределение имени проекта: CLI-аргумент → feature tag → имя сцены → "default"
static func _default_project_name() -> String:
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
