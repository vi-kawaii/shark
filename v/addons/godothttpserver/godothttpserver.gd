@tool
extends EditorPlugin

## GodotHTTPServer plugin.
## Enables the HTTPServer classes for use in your project.
## Add an HTTPServer node to your scene and configure it via code.


func _enter_tree() -> void:
	# No autoload registration - users add HTTPServer as a node in their scene.
	# This avoids naming conflicts and gives users full control over the server lifecycle.
	pass


func _exit_tree() -> void:
	pass


func _get_plugin_icon():
	return preload("res://addons/godothttpserver/godothttpserver.png")