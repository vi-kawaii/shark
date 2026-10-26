extends "res://core/exit_on_esc.gd"

const save := preload("res://core/savemanager.gd")
const player := preload("res://player/main.tscn")

@export var spawn_point: Node3D

func _ready() -> void:
	print("hi world, its shark 🦈")

	var s = save.read()
	if s == null:
		s = SaveFile.new()
		s.data = {"visits": 0}
	s.data.visits = int(s.data.get("visits", 0)) + 1
	save.write(s)
	print("shark visits = ", s.data.visits)

	spawn_player(s)

func spawn_player(s):
	var p = player.instantiate()
	add_child(p)

	if s.data.has("player_position"):
		var pos = s.data.player_position
		pos.global_position = Vector3(p.x, p.y, p.z)
	elif spawn_point:
		p.global_position = spawn_point.global_position
