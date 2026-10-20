extends Core

func use_config() -> Dictionary:
	return {
		path = "path"
	}

func use_content(data) -> void:
	print(data)
