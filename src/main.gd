extends "res://src/core/exit_on_esc.gd"

const resolve = preload("res://src/core/resolve.gd")

const save = preload("res://src/core/save/main.gd")

func _ready():
	print("hi world, its shark 🦈")
	print(resolve.main())

	var s = save.read()
	if s == null:
		s = SaveFile.new()
		s.data = {"visits": 0}
	s.data.visits = int(s.data.get("visits", 0)) + 1
	save.write(s)
	print("shark visits = ", s.data.visits)
