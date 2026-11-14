extends CanvasLayer

class_name loading_screen

var progress_bar: ProgressBar
var percent_label: Label

func _ready() -> void:
	hide()

	loading_manager.get_instance().loading_started.connect(_on_loading_started)
	loading_manager.get_instance().progress_updated.connect(_on_progress_updated)
	loading_manager.get_instance().loading_finished.connect(_on_loading_finished)

	var control = Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(control)

	progress_bar = ProgressBar.new()
	progress_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	progress_bar.custom_minimum_size = Vector2(400, 20)
	control.add_child(progress_bar)

	percent_label = Label.new()
	percent_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	control.add_child(percent_label)

func _on_loading_started() -> void:
	progress_bar.value = 0.0
	percent_label.text = "0%"

	show()

func _on_progress_updated(progress: float) -> void:
	var percent := progress * 100.0
	progress_bar.value = percent
	percent_label.text = "%d%%" % int(percent)

func _on_loading_finished() -> void:
	hide()
