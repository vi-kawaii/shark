extends RefCounted

const AstScript = preload("res://core/ast.gd")
const DslOutputScript = preload("res://core/output.gd")

var state: Dictionary = {}
var errors: Array = []
var output

func _init(p_output = null) -> void:
	output = p_output if p_output != null else DslOutputScript.new()

func run(ast: Array) -> void:
	state.clear()
	errors.clear()
	for node in ast:
		if node is AstScript.BlockDef:
			_exec_block(node)
		elif node is AstScript.Command:
			_exec_command(node)

func _exec_block(b) -> void:
	var props: Dictionary = {}
	if b.parent != "":
		if state.has(b.parent):
			props = state[b.parent].duplicate(true)
		else:
			errors.append({"line": b.line, "msg": "unknown parent: %s" % b.parent})
	for k in b.props:
		props[k] = _coerce(b.props[k])
	state[b.name] = props

func _exec_command(c) -> void:
	if not state.has(c.obj):
		errors.append({"line": c.line, "msg": "unknown object: %s" % c.obj})
		return
	var obj: Dictionary = state[c.obj]
	if not obj.has(c.key) and c.op != "=":
		errors.append({"line": c.line, "msg": "unknown key: %s.%s" % [c.obj, c.key]})
		return
	var cur = obj.get(c.key, 0)
	match c.op:
		"?":
			output.print_value("%s.%s = %s" % [c.obj, c.key, str(cur)])
		"+":
			obj[c.key] = _num(cur) + _num(c.operand)
		"-":
			obj[c.key] = _num(cur) - _num(c.operand)
		"=":
			obj[c.key] = _coerce(c.operand)
		_:
			errors.append({"line": c.line, "msg": "unknown op: %s" % c.op})

func _coerce(v):
	if v is String:
		var s: String = v
		if s.is_valid_int(): return s.to_int()
		if s.is_valid_float(): return s.to_float()
	return v

func _num(v):
	if v is int or v is float: return v
	var s := str(v)
	if s.is_valid_int(): return s.to_int()
	if s.is_valid_float(): return s.to_float()
	return 0
