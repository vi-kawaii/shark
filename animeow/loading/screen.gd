extends Node

class_name loading_screen

#@onready var progress_bar: ProgressBar = $Control/ProgressBar
#@onready var percent_label: Label = $Control/Label

#func _ready() -> void:
#	hide()
#	# Подписываемся на события загрузчика
#	AssetLoader.loading_started.connect(_on_loading_started)
#	AssetLoader.progress_updated.connect(_on_progress_updated)
#	AssetLoader.loading_finished.connect(_on_loading_finished)

#func _on_loading_started() -> void:
#	progress_bar.value = 0.0
#	percent_label.text = "0%"
#	show()

#func _on_progress_updated(progress: float) -> void:
#	# ProgressBar по умолчанию от 0 до 100
#	var percent := progress * 100.0
#	progress_bar.value = percent
#	percent_label.text = "%d%%" % int(percent)

#func _on_loading_finished() -> void:
#	hide()
