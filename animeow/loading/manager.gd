extends Node

class_name loading_manager

signal loading_started
signal progress_updated(percent: float)
signal loading_finished

var loads: Array[Array]

var loaded: int
var is_loading: bool

static var instance: loading_manager

static func get_instance() -> loading_manager:
	if instance:
		return instance

	instance = loading_manager.new()

	return instance

func get_asset_path(filename: String):
	return "res://assets/{0}".format([filename])

func start_loading() -> void:
	is_loading = true

	for l in loads:
		var path: String = l[0]

		ResourceLoader.load_threaded_request(get_asset_path(path))

	loading_started.emit()

func _process(_delta: float) -> void:
	if not is_loading:
		return

	for l in loads:
		var path: String = l[0]
		var callback: Callable = l[1]

		var status := ResourceLoader.load_threaded_get_status(get_asset_path(path))

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var res = ResourceLoader.load_threaded_get(get_asset_path(path))
				callback.call(res)
				loaded += 1

	if loaded == loads.size():
		is_loading = false
		loading_finished.emit()
		end_loading()

		return

	progress_updated.emit(float(loaded) / loads.size())

func end_loading():
	loaded = 0
	loads.clear()
