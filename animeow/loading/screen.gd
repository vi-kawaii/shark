extends CanvasLayer

class_name loading_screen

const FADE_OUT_TIME := .5
const FADE_IN_TIME := 1.
const COMPLETE_DELAY := 0.5
const SCENE_DELAY := 1.
const PROGRESS_SPEED := 5.0

var is_loading := false
var is_transitioning := false

var target_progress := 0.0
var current_progress := 0.0

var after_load_code: Callable

var background: ColorRect
var container: Control
var progress_bg: ColorRect
var progress_fill: ColorRect

func _ready() -> void:
	layer = 100
	hide()

	var lm := loading_manager.get_instance()
	lm.loading_started.connect(on_loading_started)
	lm.progress_updated.connect(on_progress_updated)
	lm.loading_finished.connect(on_loading_finished)

	create_ui()

func create_ui() -> void:
	background = ColorRect.new()
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate.a = 1.0
	add_child(background)

	# Контейнер прогресс-бара
	container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.position = Vector2(-180, 0)
	container.size = Vector2(360, 10)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.modulate.a = 1.0
	background.add_child(container)

	# Фоновая полоса
	progress_bg = ColorRect.new()
	progress_bg.color = Color(0.22, 0.22, 0.22, 1.0)
	progress_bg.size = Vector2(360, 3)
	progress_bg.position = Vector2(0, 0)
	container.add_child(progress_bg)

	# Заполнение
	progress_fill = ColorRect.new()
	progress_fill.color = Color.WHITE
	progress_fill.size = Vector2(0, 3)
	progress_fill.position = Vector2.ZERO
	container.add_child(progress_fill)

func on_loading_started() -> void:
	is_loading = true
	is_transitioning = false

	target_progress = 0.0
	current_progress = 0.0

	update_ui()

	show()

func _process(delta: float) -> void:
	if not is_loading or is_transitioning:
		return

	var t := PROGRESS_SPEED * delta
	t = minf(t, 1.0)

	current_progress = lerpf(
		current_progress,
		target_progress,
		t
	)

	update_ui()

func update_ui() -> void:
	progress_fill.size.x = 360.0 * current_progress

func on_progress_updated(progress: float) -> void:
	target_progress = clampf(progress, 0.0, 1.0)

func on_loading_finished() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	target_progress = 1.0

	finish_loading()


func finish_loading() -> void:
	target_progress = 1.0

	var elapsed := 0.0

	while current_progress < 0.999 and elapsed < 2.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	#current_progress = 1.0
	#update_ui()
	#progress_fill.size.x = 360.0 * current_progress

	# 1. Плавно уходим в полный чёрный экран
	var progress_fill_finish := create_tween()
	progress_fill_finish.tween_property(
		progress_fill,
		"size:x",
		360.0,
		FADE_OUT_TIME
	)

	await progress_fill_finish.finished

	await get_tree().create_timer(COMPLETE_DELAY, true).timeout

	# 1. Плавно уходим в полный чёрный экран
	var fade_out := create_tween()
	fade_out.tween_property(
		container,
		"modulate:a",
		0.0,
		FADE_OUT_TIME
	)

	await fade_out.finished

	# 2. Меняем сцену под чёрным экраном
	if after_load_code.is_valid():
		after_load_code.call()

	await get_tree().process_frame

	await get_tree().create_timer(
		SCENE_DELAY,
		true
	).timeout

	# 3. Проявляем новую сцену из чёрного
	var fade_in := create_tween()
	fade_in.tween_property(
		background,
		"modulate:a",
		0.0,
		FADE_IN_TIME
	)

	await fade_in.finished

	# 4. Завершаем переход
	is_loading = false
	is_transitioning = false
	hide()
