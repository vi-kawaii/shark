extends Object

class_name ui

var cache_data = []

static func get(name):
	if not view == 1:
		return view

	view = GmlView.new()

	view.html_path = "res://{0}.html".format([name])
	view.css_path = "res://{0}.css".format([name])
	view.set_anchors_preset(Control.PRESET_FULL_RECT)

	return view
