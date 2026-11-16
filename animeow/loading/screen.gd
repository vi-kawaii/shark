extends CanvasLayer

class_name loading_screen

const DOT_COUNT := 5
const DOT_RADIUS := 30.0
const DOT_SIZE := 4.0
const SPIN_SPEED := 6.0
const SPEED_MIN := 0.35 # сильнее замедление в кучной точке
const MIN_GAP_FAST := 0.20 # разреженная фаза
const MIN_GAP_SLOW := 0.05 # кучная фаза
const FOLLOW_LERP := 12.0
const KUCHNOST_ANGLE := 0.0 # 0..1, где кучность (0 = старт, 0.5 = напротив)

var _dots: Array[Panel] = []
var _angles: PackedFloat32Array = []
var _lead_angle: float = 0.0
var _time: float = 0.0
var _is_loading: bool = false

var after_load_code: Callable

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	hide()

	var lm := loading_manager.get_instance()
	lm.loading_started.connect(_on_loading_started)
	lm.progress_updated.connect(_on_progress_updated)
	lm.loading_finished.connect(_on_loading_finished)

	# Чёрный фон на весь экран
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Слой для точек
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)

	# Круглая точка через StyleBoxFlat
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	var r := int(DOT_SIZE / 2.0)
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r

	_angles.resize(DOT_COUNT)

	for i in DOT_COUNT:
		var dot := Panel.new()
		dot.size = Vector2(DOT_SIZE, DOT_SIZE)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", sb)
		canvas.add_child(dot)
		_dots.append(dot)

func _process(delta: float) -> void:
	if not _is_loading:
		return

	_time += delta
	var center := get_viewport().get_visible_rect().size * 0.5

	# Позиция ведущей точки на круге, 0..1
	var angle_norm := fposmod(_lead_angle / TAU, 1.0)

	# Кучность: 1 в KUCHNOST_ANGLE, 0 напротив
	var phase := 0.5 + 0.5 * cos((angle_norm - KUCHNOST_ANGLE) * TAU)

	# Скорость ведущей: медленно в кучной фазе, быстро в разреженной
	var speed_factor = lerp(1.0, SPEED_MIN, phase)
	_lead_angle += delta * SPIN_SPEED * speed_factor

	# Целевой зазор зависит от фазы
	var target_gap = lerp(MIN_GAP_FAST, MIN_GAP_SLOW, phase)

	for i in _dots.size():
		var target: float
		if i == 0:
			target = _lead_angle
		else:
			target = _angles[i - 1] - target_gap

		var t := 1.0 - exp(-FOLLOW_LERP * delta)
		_angles[i] = lerp(_angles[i], target, t)

		var pos := center + Vector2(cos(_angles[i]), sin(_angles[i])) * DOT_RADIUS
		_dots[i].position = pos - Vector2(DOT_SIZE, DOT_SIZE) * 0.5

func _on_loading_started() -> void:
	_is_loading = true
	_time = 0.0
	_lead_angle = 0.0
	for i in _dots.size():
		_angles[i] = - float(i) * MIN_GAP_FAST
	show()

func _on_progress_updated(_progress: float) -> void:
	pass

func _on_loading_finished() -> void:
	_is_loading = false
	hide()
	if after_load_code.is_valid():
		after_load_code.call()
