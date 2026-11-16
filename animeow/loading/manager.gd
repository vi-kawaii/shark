extends Node

class_name loading_manager

signal loading_started
signal progress_updated(percent: float)
signal loading_finished

static var instance: loading_manager

static func get_instance() -> loading_manager:
	if instance == null or not is_instance_valid(instance):
		instance = loading_manager.new()
		instance.name = "LoadingManager"
		# Engine.get_main_loop() возвращает SceneTree
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			push_error("LoadingManager: SceneTree недоступен")
			return null
		tree.root.add_child.call_deferred(instance)
	return instance

# Очередь: { "путь/к/файлу": Callable_колбэк }
var load_queue: Dictionary = {}
var active_loads: Dictionary = {}
var total_files: int = 0
var loaded_files: int = 0
var _is_loading: bool = false

func add_to_queue(path: String, callback: Callable) -> void:
	if load_queue.has(path) or active_loads.has(path):
		push_warning("LoadingManager: '%s' уже в очереди" % path)
		return
	load_queue[path] = callback

func start_loading() -> void:
	if load_queue.is_empty():
		return
	if _is_loading:
		push_warning("LoadingManager: загрузка уже идёт")
		return

	_is_loading = true
	total_files = load_queue.size()
	loaded_files = 0

	loading_started.emit()

	for path in load_queue.keys():
		ResourceLoader.load_threaded_request(path)
		active_loads[path] = load_queue[path]
	load_queue.clear()

func _process(_delta: float) -> void:
	if active_loads.is_empty():
		return

	var finished_paths: Array[String] = []
	var progress_sum: float = 0.0

	for path in active_loads.keys():
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)

		# progress[0] валиден только пока ресурс грузится
		if progress.size() > 0:
			progress_sum += progress[0]

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var res = ResourceLoader.load_threaded_get(path)
				var callback: Callable = active_loads[path]
				if callback.is_valid():
					callback.call(res)
				finished_paths.append(path)
				loaded_files += 1

			ResourceLoader.THREAD_LOAD_FAILED, \
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("LoadingManager: не удалось загрузить '%s'" % path)
				finished_paths.append(path)
				loaded_files += 1

	for path in finished_paths:
		active_loads.erase(path)

	# Прогресс: уже загруженные + средний прогресс активных
	var total_progress: float
	if active_loads.is_empty():
		total_progress = 1.0
	else:
		var avg := progress_sum / float(active_loads.size())
		total_progress = (float(loaded_files) + avg) / float(total_files)

	progress_updated.emit(total_progress)

	if active_loads.is_empty():
		_is_loading = false
		loading_finished.emit()
