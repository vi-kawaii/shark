extends Control

@onready var control_panel = preload("res://control_panel.tscn").instantiate()
@onready var preview = preload("res://preview.tscn").instantiate()

@onready var save = preload("res://save.gd").new()

@onready var server = $HTTPServer

var html = """
<style>:root{color-scheme:dark;}</style>
<button id="change">Change emotion</button>
<script>
change.onclick = async () => console.log(await (await fetch('/')).text());
</script>
"""

func _ready():
	var icon = preload("res://assets/avatar.png").get_image()
	NativeTray.init_tray("My Game", icon)
	NativeTray.hide_window()

	NativeTray.on_tray_left_clicked.connect(func():
			NativeTray.show_window()
	)

	NativeTray.add_menu_item(1, "Open", false, false)
	NativeTray.add_menu_item(2, "Exit", false, false)
	NativeTray.on_menu_item_selected.connect(_on_menu)

	print("hi world, its shark 🦈")

	# var s = save.read()
	# if s == null:
	# 	s = savefile.new()
	# 	s.data = {"visits": 0}
	# s.data.visits = int(s.data.get("visits", 0)) + 1
	# save.write(s)

	# print("shark visits = ", s.data.visits)

	add_child(preview)
	add_child(control_panel)

	server.router.handle_get("/", func(_p, _q, _h, _b):
		var res = HTTPResponse.ok(html)
		res.set_header("Content-Type", "text/html; charset=utf-8")
		return res
	)
	server.start(8080)

func _on_menu(id: int):
	match id:
		1: NativeTray.show_window()
		2: get_tree().quit()
