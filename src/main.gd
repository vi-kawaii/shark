extends Node

const animeow = preload("res://src/animeow/main.gd")
const v = preload("res://src/v/main.gd")

func _ready():
	print("hi world, its shark 🦈")

	print(animeow.main())
	print(v.main())

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
