extends Node

func _ready():
	print("hi world, its shark 🦈")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
