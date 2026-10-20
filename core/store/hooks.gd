extends Object
class_name Store

static var stores: Dictionary = {}

static func create(project_name: String, type: Variant) -> Variant:
	var store_path = Project.get_store_path_for(project_name)

	var store = type.new()
	stores[store_path] = store

	return store

static func use(project_name: String, type: Variant) -> Variant:
	var store_path = Project.get_store_path_for(project_name)

	if stores.has(store_path):
		return stores[store_path]

	return create(store_path, type)
