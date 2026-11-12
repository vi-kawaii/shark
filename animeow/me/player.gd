extends CharacterBody3D

class_name player

@onready var state := player_state.new()
@onready var speed := player_speed.new()
@onready var physics := player_physics.new()
@onready var crouch := player_crouch.new()

@onready var camera_rig := camera_third_person.new()

var _default_height: float
var _capsule: CapsuleShape3D

func _ready() -> void:
	var collision := CollisionShape3D.new()
	collision.shape = CapsuleShape3D.new()
	add_child(collision)

	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var mesh := MeshInstance3D.new()
	mesh.mesh = CapsuleMesh.new()
	visual.add_child(mesh)

	add_child(camera_rig)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_capsule = collision.shape as CapsuleShape3D
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
	_capsule.height = crouch.get_capsule_height(_default_height, state.crouch)
	camera_rig.position.y = crouch.get_camera_height(state.crouch)

func _handle_horizontal(delta) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (camera_rig.get_yaw_basis() * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0.1:
		var s := speed.get_value(_current_move_mode())
		var accel: float = physics.acceleration if is_on_floor() else physics.air_acceleration
		velocity = apply_horizontal(direction, s, accel, delta)
	elif is_on_floor():
		velocity = apply_friction(delta)

func _current_move_mode() -> player_speed.MoveMode:
	if state.crouch:
		return player_speed.MoveMode.CROUCH
	if Input.is_action_pressed("sprint"):
		return player_speed.MoveMode.RUN
	return player_speed.MoveMode.WALK

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
