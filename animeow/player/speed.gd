extends Resource

class_name player_speed

enum MoveMode { WALK, RUN, CROUCH }

@export var walk := 5.0
@export var run := 9.0
@export var crouch := 2.5

func get_value(mode: MoveMode) -> float:
	match mode:
		MoveMode.CROUCH: return crouch
		MoveMode.RUN: return run
		_: return walk
