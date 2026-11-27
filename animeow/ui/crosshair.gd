extends Control

class_name ui_crosshair

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _draw() -> void:
	var center := size / 2
	draw_circle(center, 3.0, Color.WHITE)
