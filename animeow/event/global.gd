extends Object

class_name event_global

signal loading_started
signal progress_updated
signal loading_finished

signal camera_rig_changed

var progress: float:
	set(value):
		progress = value
		progress_updated.emit()

var camera_rig: Node3D:
	set(value):
		camera_rig = value
		camera_rig_changed.emit()

static var instance: event_global

static func get_instance() -> event_global:
	if instance:
		return instance

	instance = event_global.new()
	return instance
