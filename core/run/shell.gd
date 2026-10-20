extends RefCounted
class_name Shell

static func run(what: String, command: String) -> void:
    match what:
        "game":
            game(command)
        "app":
            app(command)
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
