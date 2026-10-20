extends SceneTree

const shell = preload("res://core/run/shell.gd")
const CACHE_PATH = "user://last_command.txt"

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()

    if args.is_empty():
        if FileAccess.file_exists(CACHE_PATH):
            var file = FileAccess.open(CACHE_PATH, FileAccess.READ)
            args = file.get_as_text().split(" ", false)
        else:
            quit(1)
            return
    else:
        var file = FileAccess.open(CACHE_PATH, FileAccess.WRITE)
        file.store_string(" ".join(args))

    if args.size() < 2:
        quit(1)
        return

    shell.run(args[0], args[1])
    quit()
