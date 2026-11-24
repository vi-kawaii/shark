extends CanvasLayer

class_name loading_screen

var is_loading := false
var is_transitioning := false

var target_progress := 0.0
var current_progress := 0.0

var background: ColorRect
var container: Control
var progress_bg: ColorRect
var progress_fill: ColorRect

func _ready() -> void:
	layer = 100
	hide()

	loading.started.connect(started)
	loading.updated.connect(updated)
	loading.finished.connect(finished)

	create_ui()

func create_ui() -> void:
	background = ColorRect.new()
	background.color = Color.WHITE
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate.a = 1.0
	add_child(background)

	container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.position = Vector2(-180, 0)
	container.size = Vector2(360, 10)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.modulate.a = 1.0
	background.add_child(container)

	progress_bg = ColorRect.new()
	progress_bg.color = Color(0.85, 0.85, 0.85, 1.0)
	progress_bg.size = Vector2(360, 3)
	progress_bg.position = Vector2(0, 0)
	container.add_child(progress_bg)

	progress_fill = ColorRect.new()
	progress_fill.color = Color.BLACK
	progress_fill.size = Vector2(0, 3)
	progress_fill.position = Vector2.ZERO
	container.add_child(progress_fill)

func started() -> void:
	is_loading = true
	is_transitioning = false

	target_progress = 0.0
	current_progress = 0.0

	update_ui()

	show()

func _process(delta: float) -> void:
	if not is_loading or is_transitioning:
		return

	var t := 5.0 * delta
	t = minf(t, 1.0)

	current_progress = lerpf(
		current_progress,
		target_progress,
		t
	)

	update_ui()

func update_ui() -> void:
	progress_fill.size.x = 360.0 * current_progress

func updated() -> void:
	target_progress = clampf(loading.progress, 0.0, 1.0)

func finished() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	target_progress = 1.0

	finish_loading()

func finish_loading() -> void:
	await create_tween().tween_property(progress_fill, "size:x", 360.0, 0.5).finished
	await create_tween().tween_property(container, "modulate:a", 0.0, 1.0).finished
	await create_tween().tween_property(background, "modulate:a", 0.0, 1.0).finished

	is_loading = false
	is_transitioning = false

	hide()
