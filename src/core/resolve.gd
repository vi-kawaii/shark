extends Object

const animeow = preload("res://src/animeow/main.gd")
const v = preload("res://src/v/main.gd")

const project = preload("res://src/core/project/main.gd")

static func main():
	var target = project.name()
	match target:
		"animeow":
			return animeow.main()
		"v":
			return v.main()
		_:
			return "unknown arg: %s" % target
