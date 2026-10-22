extends Object

const util = preload("res://core/util/main.gd")

static var path

static func _static_init():
	path = util.cmd_arg()
	# path = util.cmd_arg() if util.cmd_arg() else util.feature_tag()

static func get_value():
	return path
