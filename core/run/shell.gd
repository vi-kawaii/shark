extends SceneTree
class_name Shell

static func run(what: String, command: String = "") -> void:
	match what:
		"game":
			game(command)
		"app":
			app(command)
		"lang":
			lang(command)
		_:
			pass

static func game(command: String) -> void:
	match command:
		"animeow":
			print("animeow game ran")
		_:
			pass

static func app(command: String) -> void:
	match command:
		"v":
			print("v app ran")
		_:
			pass

static func lang(command: String) -> void:
	var r = preload("res://core/dsl/main.gd").demo()
	print("--- output ---")
	for l in r.output: print(l)
	print("--- state ---")
	print(r.state)
	print("--- errors ---")
	print(r.errors)

	return
