extends Object

const _cmd_arg = preload("res://core/util/cmd_arg.gd")
# const feature_tag = preload("res://core/util/feature_tags.gd")

static func cmd_arg():
	return _cmd_arg.get_value()

# static func feature_tag() -> String:
# 	return feature_tag.get(tag)
