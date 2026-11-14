extends Node

class_name loading_manager

signal loading_started
signal progress_updated(percent: float)
signal loading_finished

static var instance: loading_manager
static func get_instance() -> loading_manager:
	if instance == null: instance = loading_manager.new()
	return instance

# Очередь: { "путь/к/файлу": Callable_колбэк }
var load_queue = {}
var active_loads = {}
var total_files = 0
var loaded_files = 0

func add_to_queue(path: String, callback: Callable):
	load_queue[path] = callback
	total_files += 1

func start_loading():
	if load_queue.is_empty():
		return

	loading_started.emit() # Сигнал о начале загрузки

	for path in load_queue.keys():
		ResourceLoader.load_threaded_request(path)
		active_loads[path] = load_queue[path]
	load_queue.clear()

func _process(_delta):
	if active_loads.is_empty():
		return

	var finished_paths = []
	var current_progress_sum = 0.0

	for path in active_loads.keys():
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(path, progress)

		current_progress_sum += progress[0]

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res = ResourceLoader.load_threaded_get(path)
			var callback = active_loads[path]

			if callback.is_valid():
				callback.call(res)

			finished_paths.append(path)
			loaded_files += 1

	for path in finished_paths:
		active_loads.erase(path)

	var total_progress = (loaded_files + (current_progress_sum / max(1, active_loads.size()))) / total_files
	progress_updated.emit(total_progress)

	# Сигнал о завершении всех загрузок
	if active_loads.is_empty():
		loading_finished.emit()
