extends Node
class_name Core

func _ready() -> void:
	var config = use_config()

	var content = Content.load(config.path)

	use_content(content)

func use_config() -> Dictionary:
	return {}

func use_content(_content) -> void:
	pass
