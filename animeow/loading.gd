extends Control

@onready var label = $Label

func _ready():
	visible = false

func start():
	visible = true

	label.text = "Loading {0}%".format([20])

func finish():
	visible = false
