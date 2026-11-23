extends Resource

class_name camera_file

var camera: Camera3D:
	set(x):
		camera = x
		changed.emit()
