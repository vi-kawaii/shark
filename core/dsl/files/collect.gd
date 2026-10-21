extends Object

static func collect() -> PackedStringArray:
    print("collecting files for")
    var path := "res://your_folder/"
    return DirAccess.get_files_at(path)
