extends Node

var files: Array[Array]

var loaded: int
var is_loading: bool

var after_load_code: Callable

@onready var screen := loading_screen.new()

func _ready() -> void:
	add_child(screen)

func get_asset_path(filename: String):
	return "res://assets/{0}".format([filename])

func start(callback: Callable) -> void:
	after_load_code = callback
	is_loading = true

	for f in files:
		var path: String = f[0]

		ResourceLoader.load_threaded_request(get_asset_path(path))

	event.loading_started.emit()

func _process(_delta: float) -> void:
	if not is_loading:
		return

	for f in files:
		var path: String = f[0]
		var callback: Callable = f[1]

		var status := ResourceLoader.load_threaded_get_status(get_asset_path(path))

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var res = ResourceLoader.load_threaded_get(get_asset_path(path))
				callback.call(res)
				loaded += 1

	if loaded == files.size():
		is_loading = false
		event.loading_finished.emit()
		end()

		return

	event.progress = float(loaded) / files.size()

func end():
	loaded = 0
	files.clear()
	after_load_code.call()
