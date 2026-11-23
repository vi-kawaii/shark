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

signal camera_rig_changed

var camera_rig: Node3D:
	set(x):
		camera_rig = x
		camera_rig_changed.emit()

@warning_ignore("unused_signal")
signal weapon_changed

var weapon: String:
	set(x):
		weapon = x
		weapon_changed.emit()
