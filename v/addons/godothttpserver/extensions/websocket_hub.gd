class_name WebSocketHub
extends RefCounted

## Manages WebSocket rooms (channels). Supports join/leave, broadcast, targeted
## sends, and per-room join guards for authorization.

var _rooms: Dictionary = {}  # room_name -> Array[WebSocketConnection]
var _room_guards: Dictionary = {}  # room_name -> Array[Callable]

## Adds a connection to a room. Returns true when the room guard allows the join.
func join_room(ws: WebSocketConnection, room: String) -> bool:
	if not _passes_guards(ws, room):
		return false
	if not _rooms.has(room):
		_rooms[room] = []
	if not _rooms[room].has(ws):
		_rooms[room].append(ws)
	return true


## Removes a connection from a room. Returns true when it was present.
func leave_room(ws: WebSocketConnection, room: String) -> bool:
	if not _rooms.has(room):
		return false
	var members: Array = _rooms[room]
	var was_present := members.has(ws)
	members.erase(ws)
	if members.is_empty():
		_rooms.erase(room)
	return was_present


## Removes a connection from every room it joined. Called on disconnect.
func leave_all(ws: WebSocketConnection) -> void:
	for room: String in _rooms.keys():
		var members: Array = _rooms[room]
		var was_present := members.has(ws)
		members.erase(ws)
		if members.is_empty():
			_rooms.erase(room)


## Returns true when the connection is a member of the room.
func is_in_room(ws: WebSocketConnection, room: String) -> bool:
	return _rooms.has(room) and _rooms[room].has(ws)


## Returns a copy of the connections currently in a room.
func get_room(room: String) -> Array:
	return (_rooms.get(room, []) as Array).duplicate()


## Returns the list of rooms that a connection has joined.
func get_rooms_for(ws: WebSocketConnection) -> Array:
	var result: Array = []
	for room: String in _rooms.keys():
		if _rooms[room].has(ws):
			result.append(room)
	return result


## Registers an authorization guard for a room. The callable receives the
## WebSocketConnection and returns true when the join is allowed.
func register_room_guard(room: String, guard: Callable) -> void:
	if not _room_guards.has(room):
		_room_guards[room] = []
	_room_guards[room].append(guard)


## Broadcasts a message to every member of a room.
func broadcast(room: String, message: Variant, is_binary: bool = false) -> void:
	if not _rooms.has(room):
		return
	var members := (_rooms[room] as Array).duplicate()
	for ws in members:
		if ws.is_closed():
			continue
		if is_binary:
			ws.send_binary(message if message is PackedByteArray else PackedByteArray())
		else:
			ws.send_text(str(message))


## Sends a message to a single connection.
func send_to(ws: WebSocketConnection, message: Variant, is_binary: bool = false) -> void:
	if ws == null or ws.is_closed():
		return
	if is_binary:
		ws.send_binary(message if message is PackedByteArray else PackedByteArray())
	else:
		ws.send_text(str(message))


## Number of rooms currently tracked.
func room_count() -> int:
	return _rooms.size()


## Number of registered guards.
func guard_count() -> int:
	return _room_guards.size()


## Clears all rooms and guards.
func clear() -> void:
	_rooms.clear()
	_room_guards.clear()


func _passes_guards(ws: WebSocketConnection, room: String) -> bool:
	if not _room_guards.has(room):
		return true
	for guard: Callable in _room_guards[room]:
		if not guard.call(ws):
			return false
	return true
