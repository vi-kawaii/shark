extends Node

signal files_changed(files: Array)

var _watch_files: Array[String] = []
var _last_mtime: Dictionary = {}
var _timer: Timer
var _restart_pending := false
var _enabled := false


static func attach(parent: Node) -> Node:
	if not ("--watch" in OS.get_cmdline_user_args()):
		return null

	var script: GDScript = load("res://watcher.gd")
	var w: Node = script.new()
	parent.add_child(w)
	w.start()
	w.files_changed.connect(func(files):
		print("[main] перезапуск из-за: ", files)
		parent.restart()
	)
	return w


func start() -> void:
	if _enabled:
		return
	_enabled = true

	_scan_watch_files("res://")

	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.autostart = true
	_timer.timeout.connect(_check_file_changes)
	add_child(_timer)

	print("[watcher] мониторю ", _watch_files.size(), " html/css файлов")


func stop() -> void:
	_enabled = false
	if _timer:
		_timer.stop()
		_timer.queue_free()
		_timer = null


func _scan_watch_files(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if not name.begins_with("."):
			var full = path.path_join(name)
			if dir.current_is_dir():
				_scan_watch_files(full)
			elif name.ends_with(".html") or name.ends_with(".css"):
				_watch_files.append(full)
				_last_mtime[full] = FileAccess.get_modified_time(full)
		name = dir.get_next()
	dir.list_dir_end()


func _check_file_changes() -> void:
	if _restart_pending:
		return

	var changed: Array = []
	for f in _watch_files:
		var t = FileAccess.get_modified_time(f)
		if t != _last_mtime.get(f, 0):
			_last_mtime[f] = t
			changed.append(f)

	if changed.is_empty():
		return

	for f in changed:
		print("[watcher] изменён: ", f)

	_restart_pending = true
	files_changed.emit(changed)
	# _restart_pending сбрасывается в main.restart() через watcher.reset()
	# либо сам узел будет удалён и создан заново


func reset() -> void:
	_restart_pending = false
