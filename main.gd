extends Node

const dsl_input = preload("res://core/input.gd")
const DslLexerScript = preload("res://core/lexer.gd")
const DslParserScript = preload("res://core/parser.gd")
const DslOutputScript = preload("res://core/output.gd")
const DslInterpreterScript = preload("res://core/interpreter.gd")

func _ready() -> void:
	demo()

func run_string(src: String) -> Dictionary:
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

func run_file(path: String) -> Dictionary:
	return run_string(dsl_input.from_file(path))

func demo() -> Dictionary:
	print("Hello world, its demo")
	return run_file("res://main.pln")
