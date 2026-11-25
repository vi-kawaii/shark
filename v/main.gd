extends Control

@onready var control_panel = preload("res://control_panel.tscn").instantiate()
@onready var preview = preload("res://preview.tscn").instantiate()

@onready var save = preload("res://save.gd").new()

@onready var server = $HTTPServer

var _dummy_output = RefCounted.new()

func _ready():
	if DisplayServer.has_method("register_additional_output"):
		DisplayServer.register_additional_output(_dummy_output)

	await get_tree().process_frame

	# Делаем окно прозрачным для кликов (мышь проходит сквозь него на рабочий стол)
	var polygon = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	DisplayServer.window_set_mouse_passthrough(polygon)

	# Сворачиваем окно в панель задач (благодаря register_additional_output Spout не встанет)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

	print("hi world, its shark 🦈")

	var s = save.read()
	if s == null:
		s = savefile.new()
		s.data = {"visits": 0}
	s.data.visits = int(s.data.get("visits", 0)) + 1
	save.write(s)

	print("shark visits = ", s.data.visits)

	add_child(preview)
	add_child(control_panel)

	server.use(StaticFileMiddleware.new())
	server.router.handle_get("/", func(_p, _q, _h, _b):
		var string = "Hello world, the counter of shark visits is {0}".format([save.data.visits])
		return HTTPResponse.ok(string)
	)
	server.start(8080)
