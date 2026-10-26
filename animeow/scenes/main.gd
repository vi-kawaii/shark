extends "res://core/exit_on_esc.gd"

const save := preload("res://core/savemanager.gd")
const player := preload("res://player/main.tscn")

func _ready() -> void:
	print("hi world, its shark 🦈")

	var s = save.read()
	if s == null:
		s = SaveFile.new()
		s.data = {"visits": 0}
	s.data.visits = int(s.data.get("visits", 0)) + 1
	save.write(s)
	print("shark visits = ", s.data.visits)

	var p = player.instantiate()
	add_child(p)

	p.camera_rig.camera.make_current()
