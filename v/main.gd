extends Node

var project = preload("res://v/core/project.gd")

func _ready() -> void:
	#test_store()
	var persistence = test_load()

	print(persistence.data)

	#test_save()

func test_store():
	var store = Store.use(project.name, project.store_type)

	store.data = 42

	print(store.data)

func test_load() -> Dictionary:
	return Persistence.load(project.name, project.save_type)

func test_save() -> void:
	Persistence.save(project.name, { data = 42 })
