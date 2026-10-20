extends RefCounted

func from_string(src: String) -> String:
	return src

func from_file(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("DslInput: cannot open %s" % path)
		return ""
	return f.get_as_text()
