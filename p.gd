extends SceneTree

const ROOT := ""  # пусто = папка, где лежит скрипт

func _init() -> void:
	var root := ROOT
	if root == "":
		root = ProjectSettings.globalize_path("res://") # для запуска через редактор
		# при --script путь к скрипту доступен так:
		if OS.has_environment("GDSCRIPT_PATH"):
			root = OS.get_environment("GDSCRIPT_PATH").get_base_dir()

	var input := root.path_join("deepseek.txt")

	if not FileAccess.file_exists(input):
		printerr("deepseek.txt not found: ", input)
		quit(1)
		return

	var text := FileAccess.get_file_as_string(input)
	var lines := text.split("\n", true)  # true = keep empty; \r срежем ниже

	var writes: Array = []
	var cur_path: String = ""
	var in_block := false
	var buf: Array = []

	var path_re := RegEx.create_from_string("^###\\s+\\d+\\.\\s+`([^`]+)`")
	var fence_open_re := RegEx.create_from_string("^```[A-Za-z0-9_+#.\\-]+\\s*$")
	var fence_close_re := RegEx.create_from_string("^```\\s*$")

	for raw_line in lines:
		var line: String = raw_line
		if line.ends_with("\r"):
			line = line.substr(0, line.length() - 1)

		if not in_block and cur_path == "":
			var m := path_re.search(line)
			if m:
				cur_path = m.get_string(1)
			continue

		if not in_block and cur_path != "":
			if fence_open_re.search(line):
				in_block = true
				buf = []
			continue

		if in_block:
			if fence_close_re.search(line):
				writes.append({"path": cur_path, "lines": buf})
				cur_path = ""
				in_block = false
				buf = []
			else:
				buf.append(line)

	if in_block:
		printerr("unterminated code block for '%s'" % cur_path)
		quit(2)
		return

	if writes.size() == 0:
		printerr("no '### N. `path`' + fenced blocks found; deepseek.txt left untouched")
		quit(3)
		return

	# валидация путей
	for w in writes:
		var rel: String = String(w["path"]).strip_edges()
		while rel.begins_with("./") or rel.begins_with(".\\") or rel.begins_with("/") or rel.begins_with("\\"):
			rel = rel.substr(1) if rel.begins_with("/") or rel.begins_with("\\") else rel.substr(2)
		if rel.is_absolute_path():
			printerr("absolute path not allowed: ", w["path"])
			quit(2)
			return
		var parts := rel.replace("\\", "/").split("/", false)
		for p in parts:
			if p == "..":
				printerr("'..' not allowed: ", w["path"])
				quit(2)
				return
		w["path"] = rel

	# запись файлов
	for w in writes:
		var full: String = root.path_join(String(w["path"]))
		var dir := full.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var f := FileAccess.open(full, FileAccess.WRITE)
		if f == null:
			printerr("cannot write: ", full, " (", FileAccess.get_open_error(), ")")
			quit(4)
			return
		var content: String = "\r\n".join(PackedStringArray(w["lines"]))
		f.store_string(content)
		f.close()
		print("written: ", w["path"])

	# очистить deepseek.txt
	var clear_f := FileAccess.open(input, FileAccess.WRITE)
	if clear_f:
		clear_f.store_string("")
		clear_f.close()
	print("deepseek.txt cleared. files written: ", writes.size())

	quit(0)