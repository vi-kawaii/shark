extends Node3D

class_name camera_aim

const FOV_NORMAL := 75.0
const FOV_ZOOM := 40.0

# Если нужно еще и сдвигать камеру (например, от плеча к центру):
const OFFSET := Vector3(1.7, 0.3, 2.0)
const OFFSET_ZOOM := Vector3(0.2, 0.3, -0.5)

var target_fov := FOV_NORMAL
var target_offset := OFFSET

func _process(delta: float) -> void:
	if not camera.cam:
		return

	# 1. Плавно меняем зум (приближение)
	camera.cam.fov = lerp(camera.cam.fov, target_fov, 15.0 * delta)

	# 2. Если камера дочерняя у головы/игрока, двигаем локальный position (БЕЗ +=)
	camera.cam.position = camera.cam.position.lerp(target_offset, 15.0 * delta)

func zoom() -> void:
	target_fov = FOV_ZOOM
	#target_offset = OFFSET_ZOOM

func unzoom() -> void:
	target_fov = FOV_NORMAL
	#target_offset = OFFSET
