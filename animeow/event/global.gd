extends Object

class_name event_global

static var instance: event_global

static func get_instance() -> event_global:
	if instance:
		return instance

	instance = event_global.new()
	return instance

@warning_ignore("unused_signal")
signal loading_started

signal progress_updated

var progress: float:
	set(value):
		progress = value
		progress_updated.emit()

@warning_ignore("unused_signal")
signal loading_finished

signal camera_rig_changed

var camera_rig: Node3D:
	set(value):
		camera_rig = value
		camera_rig_changed.emit()

@warning_ignore("unused_signal")
signal weapon_changed

var weapon: String
