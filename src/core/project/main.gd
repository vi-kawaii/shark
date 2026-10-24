extends Object

static func name():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0:
		return args[0]

	if OS.has_feature("animeow"):
		return "animeow"
	if OS.has_feature("v"):
		return "v"

	return "default"
