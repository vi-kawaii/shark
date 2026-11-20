extends Resource

class_name player_physics

@export var jump_velocity := 5.5
@export var acceleration := 12.0
@export var air_acceleration := 4.0
@export var friction := 14.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
