extends Object

static func cmd_arg():
	return _cmd_arg.get_value()

static func get(tag: String) -> String:
	return tag if OS.has_feature(tag) else ""

static func get_value():
	return OS.get_cmdline_user_args()[0]
