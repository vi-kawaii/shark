extends "res://src/core/exit_on_esc.gd"

const resolve_target = preload("res://src/core/resolve_target.gd")

func _ready():
	print("hi world, its shark 🦈")
	print(resolve_target.main())
