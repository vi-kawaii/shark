extends Node3D

@export var mouse := camera_mouse.new()
@export var movement := camera_movement.new()
@export var zoom := camera_zoom.new()
@export var rot := camera_rotation.new()

var spring_arm: SpringArm3D
var camera: Camera3D

func _ready() -> void:
	spring_arm = SpringArm3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.2
	spring_arm.shape = sphere
	spring_arm.spring_length = 4.0
	add_child(spring_arm)

	camera = Camera3D.new()
	spring_arm.add_child(camera)

	rot.yaw.target = rotation.y
	rot.yaw.current = rot.yaw.target
	rot.pitch.target = spring_arm.rotation.x
	rot.pitch.current = rot.pitch.target

	camera.rotation = Vector3.ZERO
	camera.position = Vector3.ZERO

	zoom.target = clampf(spring_arm.spring_length, zoom.minimum, zoom.maximum)
	zoom.current = zoom.target

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rot.yaw.target -= event.relative.x * mouse.sensitivity
		rot.pitch.target -= event.relative.y * mouse.sensitivity
		rot.pitch.target = clampf(rot.pitch.target, rot.pitch.minimum, rot.pitch.maximum)
		rot.yaw.velocity = -event.relative.x * mouse.sensitivity
		rot.pitch.velocity = -event.relative.y * mouse.sensitivity

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom.target = maxf(zoom.target - zoom.step, zoom.minimum)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom.target = minf(zoom.target + zoom.step, zoom.maximum)

func _physics_process(delta: float) -> void:
	rot.yaw.velocity = lerpf(rot.yaw.velocity, 0.0, delta * movement.smoothness)
	rot.pitch.velocity = lerpf(rot.pitch.velocity, 0.0, delta * movement.smoothness)

	rot.yaw.target += rot.yaw.velocity * delta
	rot.pitch.target = clampf(rot.pitch.target + rot.pitch.velocity * delta, rot.pitch.minimum, rot.pitch.maximum)

	rot.yaw.current = lerp_angle(rot.yaw.current, rot.yaw.target, delta * 20.0)
	rot.pitch.current = lerpf(rot.pitch.current, rot.pitch.target, delta * 20.0)
	zoom.current = lerpf(zoom.current, zoom.target, delta * zoom.smoothness)

	rotation.y = rot.yaw.current
	spring_arm.rotation.x = rot.pitch.current
	spring_arm.spring_length = zoom.current

func get_yaw_basis() -> Basis:
	return Basis(Vector3.UP, rotation.y)
