extends RefCounted

enum States {
	LOADING,
	GAME,
	PAUSE
}

enum GameSubStates {
	HUMAN,
	VEHICLE,
	DIALOG,
	CUTSCENE
}

enum GameHumanSubStates {
	WALK,
	RUN,
	IDLE,
	JUMP
}
