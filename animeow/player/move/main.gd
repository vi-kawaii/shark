extends RefCounted

static func apply_gravity(velocity: Vector3, gravity: float, delta: float) -> Vector3:
	velocity.y -= gravity * delta
	return velocity

static func apply_horizontal(
	velocity: Vector3,
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

static func apply_friction(velocity: Vector3, friction: float, delta: float) -> Vector3:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	return velocity
