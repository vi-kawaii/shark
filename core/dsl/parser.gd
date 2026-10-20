extends RefCounted

const AstBlockDefScript = preload("res://core/dsl/ast/blockdef.gd")
const AstCommandScript = preload("res://core/dsl/ast/command.gd")

var errors: Array = []

func parse(lines: Array) -> Array:
	errors.clear()
	return _parse_statements(lines, 0)[0]

func _parse_statements(lines: Array, i: int) -> Array:
	var stmts: Array = []
	while i < lines.size():
		var ln: Dictionary = lines[i]
		var content: String = ln.content
		if content.ends_with(":"):
			var header := content.substr(0, content.length() - 1).strip_edges()
			var bname := header
			var parent := ""
			if "<-" in header:
				var parts := header.split("<-", true, 1)
				bname = parts[0].strip_edges()
				parent = parts[1].strip_edges()
			var body_res := _parse_body(lines, i + 1, ln.indent)
			var blk = AstBlockDefScript.new()
			blk.name = bname
			blk.parent = parent
			blk.props = body_res[0]
			blk.line = ln.line
			stmts.append(blk)
			i = body_res[1]
		else:
			stmts.append(_parse_command(content, ln.line))
			i += 1
	return [stmts, i]

func _parse_body(lines: Array, i: int, parent_indent: int) -> Array:
	var props: Dictionary = {}
	if i >= lines.size():
		return [props, i]
	var child_indent: int = lines[i].indent
	if child_indent <= parent_indent:
		errors.append({"line": lines[i].line, "msg": "empty block body"})
		return [props, i]
	while i < lines.size() and lines[i].indent == child_indent:
		var kv := _parse_property(lines[i].content)
		props[kv[0]] = kv[1]
		i += 1
	return [props, i]

func _parse_property(content: String) -> Array:
	for j in content.length():
		var c := content[j]
		if c == " " or c == "\t" or c == ":":
			var key := content.substr(0, j).strip_edges()
			var val := content.substr(j + 1).strip_edges()
			return [key, val]
	return [content.strip_edges(), ""]

func _parse_command(content: String, line: int):
	var parts := content.split(" ", false)
	var cmd = AstCommandScript.new()
	cmd.line = line
	if parts.size() < 2:
		errors.append({"line": line, "msg": "invalid command: %s" % content})
		return cmd
	cmd.obj = parts[0]
	cmd.key = parts[1]
	if parts.size() == 2:
		cmd.op = "?"
		return cmd
	var rest := " ".join(parts.slice(2))
	if rest == "?":
		cmd.op = "?"
	elif rest.begins_with("+"):
		cmd.op = "+"; cmd.operand = rest.substr(1).strip_edges()
	elif rest.begins_with("-"):
		cmd.op = "-"; cmd.operand = rest.substr(1).strip_edges()
	elif rest.begins_with("="):
		cmd.op = "="; cmd.operand = rest.substr(1).strip_edges()
	else:
		cmd.op = "="; cmd.operand = rest
	return cmd
