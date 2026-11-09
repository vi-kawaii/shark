extends Control

@onready var control_panel = preload("res://control_panel.tscn").instantiate()
@onready var preview = preload("res://preview.tscn").instantiate()

@onready var save = preload("res://save.gd")

@onready var server = $HTTPServer

func _ready():
	print("hi world, its shark 🦈")

	save = save.read()
	if save == null:
		save = savefile.new()
		save.data = {"visits": 0}
	save.data.visits = int(save.data.get("visits", 0)) + 1
	save.write(save)

	print("shark visits = ", save.data.visits)

	add_child(preview)
	add_child(control_panel)

	server.use(StaticFileMiddleware.new())
	server.router.handle_get("/", func(_p, _q, _h, _b):
		var s = "Hello world, the counter of shark visits is {0}".format([save.data.visits])
		return HTTPResponse.ok(s)
	)
	server.start(8080)
