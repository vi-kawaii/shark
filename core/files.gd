extends RefCounted

class_name DslFiles

const collect = preload("res://core/collect.gd")

static func name():
	pass

static func collect() -> void:
	collect()

static func collect() -> PackedStringArray:
    print("collecting files for")
    var path := "res://your_folder/"
    return DirAccess.get_files_at(path)
