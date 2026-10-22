extends Node

const util = preload("res://core/main.gd")

static func _static_init():
	print("Hello world")
	print("this is project {0}".format([path.get_value()]))

static var path

static func _static_init():
	path = util.cmd_arg()

static func path():
	return path

static var global

static func _static_init():
	RenderingServer.set_default_clear_color(Color.BLACK)
