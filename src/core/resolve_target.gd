extends Object

const animeow = preload("res://src/animeow/main.gd")
const v = preload("res://src/v/main.gd")

static func main():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0:
		var target = args[0]
		match target:
			"animeow":
				return animeow.main()
			"v":
				return v.main()
			_:
				return "unknown arg: %s" % target

	if OS.has_feature("animeow"):
		return animeow.main()
	if OS.has_feature("v"):
		return v.main()

	return "no args and no feature tag"
