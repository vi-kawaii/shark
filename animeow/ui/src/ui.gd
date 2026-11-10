extends Object

class_name ui

# Статический кэш
static var cache_data: Dictionary = {}

# Возвращает обертку (используем Object, чтобы избежать циклических ссылок при парсинге)
static func get_view(name: String) -> Object:
	if cache_data.has(name) and is_instance_valid(cache_data[name]):
		return cache_data[name]

	var wrapper = UIViewWrapper.new(name)
	cache_data[name] = wrapper
	return wrapper

# Внутренний класс переименован, чтобы не было конфликтов имен
class UIViewWrapper extends Object:
	var view_name: String
	var view: GmlView

	func _init(name: String):
		view_name = name
		view = GmlView.new()
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.html_path = "res://ui/static/{0}.html".format([name])
		view.css_path = "res://ui/static/{0}.css".format([name])

		if view is Control:
			view.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Метод .add()
	func add(parent_node: Node) -> UIViewWrapper:
		if is_instance_valid(parent_node) and is_instance_valid(view):
			if view.get_parent():
				view.get_parent().remove_child(view)
			parent_node.add_child(view)
		return self

	# Метод .set_state() (вместо конфликтующего встроенного set)
	func set_state(state) -> UIViewWrapper:
		if is_instance_valid(view):
			if "state" in view:
				view.state = state
			elif view.has_method("set_state"):
				view.set_state(state)
		return self

	# Метод для удаления (вместо конфликтующего встроенного free)
	func clear() -> void:
		if is_instance_valid(view):
			view.queue_free()

		# Очищаем кэш через получение класса, чтобы обойти баг циклической ссылки
		var parent_script = (self.get_script() as Script).get_base_script()
		if parent_script and "cache_data" in parent_script:
			parent_script.cache_data.erase(view_name)

		#self.free()
