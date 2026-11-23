extends Node

@warning_ignore("unused_signal")
signal loading_started

@warning_ignore("unused_signal")
signal loading_finished

signal progress_updated

var progress: float:
	set(x):
		progress = x
		progress_updated.emit()

signal camera_changed

var camera: Node3D:
	set(x):
		camera = x
		camera_changed.emit()

@warning_ignore("unused_signal")
signal weapon_changed

var weapon: String:
	set(x):
		weapon = x
		weapon_changed.emit()
