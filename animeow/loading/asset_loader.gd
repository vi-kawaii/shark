extends RefCounted

class_name loading_asset_loader

signal loading_started
signal progress_updated(progress: float)
signal loading_finished

static var instance: loading_asset_loader

static func get_instance() -> loading_asset_loader:
	if instance == null:
		instance = loading_asset_loader.new()
	return instance

## Хранит активные загрузки: { "путь": [список_колбэков] }
#var _pending: Dictionary = {}

#func _ready() -> void:
#	set_process(false) # Выключаем _process, когда грузить нечего

#func enqueue(paths: Array[String], callback: Callable) -> void:
#	if paths.is_empty():
#		if callback.is_valid(): callback.call({})
#		return

#	var was_empty := _pending.is_empty()

#	# Счетчик для конкретно этой ноды (чтобы дождаться ВСЕХ её файлов)
#	var remaining := paths.size()
#	var node_assets := {}

#	for path in paths:
#		# Оборачиваем колбэк ноды, чтобы он сработал только когда скачается последний её файл
#		var on_file_done := func(res: Resource) -> void:
#			node_assets[path] = res
#			remaining -= 1
#			if remaining == 0 and callback.is_valid():
#				callback.call(node_assets)

#		if not _pending.has(path):
#			_pending[path] = []
#			ResourceLoader.load_threaded_request(path)

#		_pending[path].append(on_file_done)

#	if was_empty:
#		set_process(true)
#		loading_started.emit()

#func _process(_delta: float) -> void:
#	var total_progress: float = 0.0
#	var completed_paths: Array[String] = []

#	for path in _pending.keys():
#		var progress_arr := [] # Godot записывает прогресс сюда: [0.5]
#		var status := ResourceLoader.load_threaded_get_status(path, progress_arr)

#		if status == ResourceLoader.THREAD_LOAD_LOADED:
#			total_progress += 1.0
#			var res := ResourceLoader.load_threaded_get(path)
#			for cb in _pending[path]:
#				cb.call(res)
#			completed_paths.append(path)

#		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
#			total_progress += progress_arr[0]

#		else: # Ошибка загрузки (файл не найден и т.д.)
#			push_error("Ошибка загрузки: " + path)
#			for cb in _pending[path]:
#				cb.call(null)
#			completed_paths.append(path)

#	# Удаляем завершенные файлы из очереди
#	for path in completed_paths:
#		_pending.erase(path)

#	# Считаем и отправляем общий прогресс (если еще остались файлы)
#	if not _pending.is_empty():
#		var average_progress := total_progress / _pending.size()
#		progress_updated.emit(average_progress)
#	else:
#		progress_updated.emit(1.0)
#		set_process(false)
#		loading_finished.emit()
