extends Node3D
class_name CameraRig

@export var mouse_sensitivity := 0.002
@export var camera_smoothness := 18.0
@export var pitch_min := deg_to_rad(-70)
@export var pitch_max := deg_to_rad(60)
@export var zoom_step := 0.5
@export var zoom_min := 1.5
@export var zoom_max := 6.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var _target_yaw := 0.0
var _target_pitch := 0.0
var _current_yaw := 0.0
var _current_pitch := 0.0
var _yaw_velocity := 0.0
var _pitch_velocity := 0.0

func _ready() -> void:
	_target_yaw = rotation.y
	_current_yaw = _target_yaw
	_target_pitch = camera.rotation.x
	_current_pitch = _target_pitch

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_target_yaw -= event.relative.x * mouse_sensitivity
		_target_pitch -= event.relative.y * mouse_sensitivity
		_target_pitch = clampf(_target_pitch, pitch_min, pitch_max)
		_yaw_velocity = -event.relative.x * mouse_sensitivity
		_pitch_velocity = -event.relative.y * mouse_sensitivity

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = maxf(spring_arm.spring_length - zoom_step, zoom_min)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = minf(spring_arm.spring_length + zoom_step, zoom_max)

func _physics_process(delta: float) -> void:
	_yaw_velocity = lerpf(_yaw_velocity, 0.0, delta * camera_smoothness)
	_pitch_velocity = lerpf(_pitch_velocity, 0.0, delta * camera_smoothness)

	_target_yaw += _yaw_velocity * delta
	_target_pitch = clampf(_target_pitch + _pitch_velocity * delta, pitch_min, pitch_max)

	_current_yaw = lerp_angle(_current_yaw, _target_yaw, delta * 20.0)
	_current_pitch = lerpf(_current_pitch, _target_pitch, delta * 20.0)

	rotation.y = _current_yaw
	camera.rotation.x = _current_pitch

func get_yaw_basis() -> Basis:
	return Basis(Vector3.UP, rotation.y)
