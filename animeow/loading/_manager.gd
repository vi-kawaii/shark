extends Node

signal started
signal finished
signal updated

var progress: float:
	set(x):
		progress = x
		updated.emit()

var pathes: Array[String]
var files: Array[Resource]

var is_loading: bool

var after_load_code: Callable

var i: int

@onready var screen := loading_screen.new()

func _ready() -> void:
	add_child(screen)

func append_array(path: Array[String]) -> Array[int]:
	pathes.append_array(path)

	var idxs: Array[int]
	for x in path.size():
		i += 1
		idxs.append(i)

	return idxs

func start(callback: Callable) -> void:
	after_load_code = callback
	is_loading = true

	for p in pathes:
		ResourceLoader.load_threaded_request(p)

	started.emit()

func _process(_delta: float) -> void:
	if not is_loading:
		return

	for p in pathes:
		var status := ResourceLoader.load_threaded_get_status(p)

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				files.append(ResourceLoader.load_threaded_get(p))

	if files.size() == pathes.size():
		is_loading = false
		finished.emit()
		end()

		return

	progress = float(files.size()) / pathes.size()

func end():
	pathes.clear()
	after_load_code.call()
