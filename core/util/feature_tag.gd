extends Object

static func get(tag: String) -> String:
	return tag if OS.has_feature(tag) else ""
