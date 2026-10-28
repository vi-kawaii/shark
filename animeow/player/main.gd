extends CharacterBody3D

const state := preload("res://player/state/main.gd")

const crouch := preload("res://player/move/crouch.gd")
const horizontal := preload("res://player/move/horizontal.gd")
const vertical := preload("res://player/move/vertical.gd")

const CAMERA_SCENE := preload("res://player/camera/main.tscn")

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
	camera_rig = CAMERA_SCENE.instantiate()
	add_child(camera_rig)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_capsule = collision_shape.shape as CapsuleShape3D
	_default_height = _capsule.height

func _physics_process(delta: float) -> void:
	_handle_crouch()
	horizontal.update(
		self, camera_rig, _is_crouching,
		walk_speed, run_speed, crouch_speed,
		acceleration, air_acceleration, friction,
		delta
	)
	vertical.update(self, _gravity, jump_velocity, _is_crouching, delta)
	move_and_slide()

func _handle_crouch() -> void:
	var want_crouch := Input.is_action_pressed("crouch")
	if want_crouch == _is_crouching:
		return

	_is_crouching = want_crouch
	_capsule.height = state.get_capsule_height(_default_height, _is_crouching, crouch_height_ratio)
	camera_rig.position.y = state.get_camera_height(stand_camera_height, crouch_camera_height, _is_crouching)
