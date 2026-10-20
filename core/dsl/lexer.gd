extends RefCounted

var errors: Array = []

func tokenize(src: String) -> Array:
	errors.clear()
	var lines: Array = []
	var n: int = 0
	for raw in src.split("\n"):
		n += 1
		var s := raw.rstrip(" \t\r")
		var content := s.strip_edges()
		if content == "" or content.begins_with("#"):
			continue
		var indent := 0
		while indent < s.length() and (s[indent] == " " or s[indent] == "\t"):
			indent += 1
		lines.append({"indent": indent, "content": content, "line": n})
	return lines
