extends RefCounted

const DslInputScript = preload("res://core/dsl/input.gd")
const DslLexerScript = preload("res://core/dsl/lexer.gd")
const DslParserScript = preload("res://core/dsl/parser.gd")
const DslOutputScript = preload("res://core/dsl/output.gd")
const DslInterpreterScript = preload("res://core/dsl/interpreter.gd")

static func run_string(src: String) -> Dictionary:
	var lexer = DslLexerScript.new()
	var parser = DslParserScript.new()
	var output = DslOutputScript.new()
	var interpreter = DslInterpreterScript.new(output)

	var lines: Array = lexer.tokenize(src)
	var ast: Array = parser.parse(lines)
	interpreter.run(ast)

	var all_errors: Array = []
	all_errors.append_array(lexer.errors)
	all_errors.append_array(parser.errors)
	all_errors.append_array(interpreter.errors)

	return {
		"state": interpreter.state,
		"errors": all_errors,
		"output": output.get_lines(),
	}

static func run_file(path: String) -> Dictionary:
	var inp = DslInputScript.new()
	return run_string(inp.from_file(path))

static func demo() -> Dictionary:
	print(42)
	var src = "player:\n    money 1000\n    name Some Cool Name With Spaces Yeah\n\nhud <- player:\n    money: k\n    name: AaAa\n\nplayer money +20\nplayer money ?"
	return run_string(src)
