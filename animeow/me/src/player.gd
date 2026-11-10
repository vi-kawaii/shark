extends CharacterBody3D

@onready var speed := player_speed.new()
@onready var physics := player_physics.new()

@export_group("Crouch")
@export var crouch_height_ratio := 0.5
@export var stand_camera_height := 1.6
@export var crouch_camera_height := 1.0

@onready var camera_rig := preload("res://me/static/camera_rig.tscn").instantiate()
@onready var collision_shape := $CollisionShape3D

@onready var state := player_state.new()
var _default_height: float
var _capsule: CapsuleShape3D

func _ready() -> void:
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
	if want_crouch == state.crouch:
		return

	state.crouch = want_crouch
	_capsule.height = get_capsule_height(_default_height, state.crouch, crouch_height_ratio)
	camera_rig.position.y = get_camera_height(stand_camera_height, crouch_camera_height, state.crouch)

func get_speed(crouching: bool, sprinting: bool, walk: float, run: float, crouch: float) -> float:
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
		var s := get_speed(
			state.crouch,
			Input.is_action_pressed("sprint"),
			speed.walk, speed.run, speed.crouch
		)
		var accel: float = physics.acceleration if is_on_floor() else physics.air_acceleration
		velocity = apply_horizontal(direction, s, accel, delta)
	elif is_on_floor():
		velocity = apply_friction(delta)

func _handle_vertical(delta) -> void:
	if not is_on_floor():
		velocity = apply_gravity(delta)
	elif Input.is_action_just_pressed("jump") and not state.crouch:
		velocity.y = physics.jump_velocity

func apply_gravity(delta: float) -> Vector3:
	velocity.y -= physics.gravity * delta
	return velocity

func apply_horizontal(direction: Vector3, s: float, accel: float, delta: float) -> Vector3:
	if direction.length() > 0.1:
		var target := direction * s
		var step := accel * delta * s
		velocity.x = move_toward(velocity.x, target.x, step)
		velocity.z = move_toward(velocity.z, target.z, step)
	return velocity

func apply_friction(delta: float) -> Vector3:
	velocity.x = move_toward(velocity.x, 0.0, physics.friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, physics.friction * delta)
	return velocity
