extends SceneTree

const shell = preload("res://core/run/shell.gd")
const CACHE_PATH = "user://last_command.txt"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()

	if args.is_empty():
		args = _read_cache()
		if args.is_empty():
			push_error("no command and no cache")
			quit(1)
			return
	else:
		var stripped := _strip_run(args)
		_write_cache(stripped)          # пишем уже без "run"
		args = stripped

	args = _strip_run(args)             # страховка для старого кэша

	if args.is_empty():
		push_error("cache had only 'run', no domain")
		quit(1)
		return

	var what: String = args[0]
	var command: String = args[1] if args.size() > 1 else ""

	shell.run(what, command)
	quit()


func _read_cache() -> Array:
	if not FileAccess.file_exists(CACHE_PATH):
		return []
	var f = FileAccess.open(CACHE_PATH, FileAccess.READ)
	if f == null:
		return []
	var text := f.get_as_text().strip_edges()
	if text == "":
		return []
	return text.split(" ", false)


func _write_cache(args: Array) -> void:
	var f = FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(" ".join(args))


func _strip_run(args: Array) -> Array:
	if not args.is_empty() and args[0] == "run":
		return args.slice(1)
	return args
