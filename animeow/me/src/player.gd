extends CharacterBody3D

const _camera_rig := preload("res://camera_rig.tscn")

@export var walk_speed := 5.0
@export var run_speed := 9.0
@export var crouch_speed := 2.5
@export var jump_velocity := 5.5
@export var acceleration := 12.0
@export var air_acceleration := 4.0
@export var friction := 14.0

@export_group("Crouch")
@export var crouch_height_ratio := 0.5
@export var stand_camera_height := 1.6
@export var crouch_camera_height := 1.0

@onready var camera_rig
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _is_crouching := false
var _default_height: float
var _capsule: CapsuleShape3D

func _ready() -> void:
	camera_rig = _camera_rig.instantiate()
	add_child(camera_rig)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_capsule = collision_shape.shape as CapsuleShape3D
	_default_height = _capsule.height

func _physics_process(delta: float) -> void:
	_handle_crouch()
	_handle_horizontal(delta)
	_handle_vertical(delta)
	move_and_slide()

func _handle_crouch() -> void:
	var want_crouch := Input.is_action_pressed("crouch")
	if want_crouch == _is_crouching:
		return

	_is_crouching = want_crouch
	_capsule.height = get_capsule_height(_default_height, _is_crouching, crouch_height_ratio)
	camera_rig.position.y = get_camera_height(stand_camera_height, crouch_camera_height, _is_crouching)

func get_speed(
	crouching: bool,
	sprinting: bool,
	walk: float,
	run: float,
	crouch: float
) -> float:
	if crouching:
		return crouch
	if sprinting:
		return run
	return walk

func get_capsule_height(default_height: float, crouching: bool, ratio: float) -> float:
	return default_height * (ratio if crouching else 1.0)

func get_camera_height(stand: float, crouch: float, crouching: bool) -> float:
	return crouch if crouching else stand

func _handle_horizontal(delta) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (camera_rig.get_yaw_basis() * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0.1:
		var speed := get_speed(
			_is_crouching,
			Input.is_action_pressed("sprint"),
			walk_speed, run_speed, crouch_speed
		)
		var accel := acceleration if is_on_floor() else air_acceleration
		velocity = apply_horizontal(direction, speed, accel, delta)
	elif is_on_floor():
		velocity = apply_friction(delta)

func _handle_vertical(delta) -> void:
	if not is_on_floor():
		velocity = apply_gravity(delta)
	elif Input.is_action_just_pressed("jump") and not _is_crouching:
		velocity.y = jump_velocity

func apply_gravity(delta: float) -> Vector3:
	velocity.y -= _gravity * delta
	return velocity

func apply_horizontal(
	direction: Vector3,
	speed: float,
	accel: float,
	delta: float
) -> Vector3:
	if direction.length() > 0.1:
		var target := direction * speed
		var step := accel * delta * speed
		velocity.x = move_toward(velocity.x, target.x, step)
		velocity.z = move_toward(velocity.z, target.z, step)
	return velocity

func apply_friction(delta: float) -> Vector3:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	return velocity
