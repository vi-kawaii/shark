class_name WebSocketConnection
extends RefCounted

## WebSocket connection handler.
## Handles the WebSocket handshake, frame parsing, and message events.

signal message_received(data: Variant, is_binary: bool)
signal connection_closed(code: int, reason: String)

const WS_GUID := "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

const OPCODE_CONTINUATION := 0x0
const OPCODE_TEXT := 0x1
const OPCODE_BINARY := 0x2
const OPCODE_CLOSE := 0x8
const OPCODE_PING := 0x9
const OPCODE_PONG := 0xA

## Untyped on purpose: the concrete peer is a StreamPeerTCP or StreamPeerTLS,
## and both expose poll()/get_status()/get_available_bytes() outside StreamPeer.
var peer = null
var is_open: bool = false
var _buffer: PackedByteArray = PackedByteArray()
var _fragmented_opcode: int = -1
var _fragmented_data: PackedByteArray = PackedByteArray()
var _last_activity: float = 0.0
var idle_timeout: float = 60.0
var max_message_size: int = 10 * 1024 * 1024  # 10 MB
## When > 0, the server sends a ws-level ping every `ping_interval` seconds and
## closes the connection if no pong (or any inbound frame) arrives within one interval.
var ping_interval: float = 0.0
var _waiting_pong: bool = false
var _last_ping_time: float = 0.0


func _init(p_peer: StreamPeer) -> void:
	peer = p_peer
	_last_activity = Time.get_ticks_msec() / 1000.0


## Performs the WebSocket handshake. Returns true on success.
func perform_handshake(request: HTTPMessage) -> bool:
	var key := request.header("sec-websocket-key")
	if key.is_empty():
		return false

	var version := request.header("sec-websocket-version")
	if version != "13":
		return false

	var accept := _compute_accept(key)
	var response := "HTTP/1.1 101 Switching Protocols\r\n"
	response += "Upgrade: websocket\r\n"
	response += "Connection: Upgrade\r\n"
	response += "Sec-WebSocket-Accept: %s\r\n\r\n" % accept

	peer.put_data(response.to_utf8_buffer())
	is_open = true
	_last_activity = Time.get_ticks_msec() / 1000.0
	return true


## Polls the connection for incoming frames.
func poll() -> void:
	if not is_open:
		return

	peer.poll()
	var status = peer.get_status()
	if status != StreamPeerTLS.STATUS_CONNECTED:
		close(1006, "Connection lost")
		return

	var available: int = peer.get_available_bytes()
	if available > 0:
		var data: Array = peer.get_data(available)
		if data[0] == OK:
			_buffer.append_array(data[1])
			_last_activity = Time.get_ticks_msec() / 1000.0
			_waiting_pong = false
		else:
			close(1006, "Read error")
			return

	# Idle timeout
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_activity > idle_timeout:
		close(1001, "Idle timeout")
		return

	# Keep-alive: send a ping when idle, close if the pong is not answered.
	if ping_interval > 0.0:
		if not _waiting_pong and now - _last_activity >= ping_interval:
			send_ping()
			_waiting_pong = true
			_last_ping_time = now
		elif _waiting_pong and now - _last_ping_time > ping_interval:
			close(1001, "Pong timeout")
			return

	_parse_frames()


## Sends a text message.
func send_text(message: String) -> void:
	_send_frame(OPCODE_TEXT, message.to_utf8_buffer())


## Sends a binary message.
func send_binary(data: PackedByteArray) -> void:
	_send_frame(OPCODE_BINARY, data)


## Sends a ping frame.
func send_ping() -> void:
	_send_frame(OPCODE_PING, PackedByteArray())


## Closes the connection with the given code and reason.
func close(code: int = 1000, reason: String = "") -> void:
	if not is_open:
		return

	var payload := PackedByteArray()
	payload.resize(2)
	payload.encode_u16(0, code)
	payload.append_array(reason.to_utf8_buffer())
	_send_frame(OPCODE_CLOSE, payload)

	is_open = false
	peer.disconnect_from_host()
	connection_closed.emit(code, reason)


func is_closed() -> bool:
	return not is_open


# ==========================================
# INTERNAL
# ==========================================

func _compute_accept(key: String) -> String:
	var sha = HashingContext.new()
	sha.start(HashingContext.HASH_SHA256)
	var hash = (key + WS_GUID).to_utf8_buffer()
	sha.update(hash)
	return Marshalls.raw_to_base64(sha.finish())


func _parse_frames() -> void:
	while is_open and _buffer.size() >= 2:
		var b0 := _buffer[0]
		var b1 := _buffer[1]

		var fin := (b0 & 0x80) != 0
		var opcode := b0 & 0x0F
		var masked := (b1 & 0x80) != 0
		var payload_len := b1 & 0x7F

		if not masked:
			# RFC 6455: every client-to-server frame MUST be masked.
			close(1002, "Client frames must be masked")
			return

		var offset := 2

		# Extended payload lengths
		if payload_len == 126:
			if _buffer.size() < offset + 2:
				return
			payload_len = _buffer.decode_u16(offset)
			offset += 2
		elif payload_len == 127:
			if _buffer.size() < offset + 8:
				return
			payload_len = int(_buffer.decode_u64(offset))
			offset += 8

		# Check message size limit
		if payload_len > max_message_size:
			close(1009, "Message too large")
			return

		# Masking key
		var mask_key := PackedByteArray()
		if masked:
			if _buffer.size() < offset + 4:
				return
			mask_key = _buffer.slice(offset, offset + 4)
			offset += 4

		# Check if we have the full payload
		if _buffer.size() < offset + payload_len:
			return

		var payload := _buffer.slice(offset, offset + payload_len)

		# Unmask if needed
		if masked:
			for i in range(payload.size()):
				payload[i] = payload[i] ^ mask_key[i % 4]

		# Remove the frame from the buffer
		_buffer = _buffer.slice(offset + payload_len)

		_handle_frame(fin, opcode, payload)


func _handle_frame(fin: bool, opcode: int, payload: PackedByteArray) -> void:
	match opcode:
		OPCODE_TEXT, OPCODE_BINARY:
			if not fin:
				# Start of a fragmented message
				_fragmented_opcode = opcode
				_fragmented_data = payload
			else:
				_emit_message(opcode, payload)

		OPCODE_CONTINUATION:
			if _fragmented_opcode == -1:
				close(1002, "Unexpected continuation frame")
				return
			_fragmented_data.append_array(payload)
			if fin:
				_emit_message(_fragmented_opcode, _fragmented_data)
				_fragmented_opcode = -1
				_fragmented_data = PackedByteArray()

		OPCODE_CLOSE:
			var code := 1000
			var reason := ""
			if payload.size() >= 2:
				code = payload.decode_u16(0)
				reason = payload.slice(2).get_string_from_utf8()
			# Echo close frame back
			var close_payload := PackedByteArray()
			close_payload.resize(2)
			close_payload.encode_u16(0, code)
			_send_frame(OPCODE_CLOSE, close_payload)
			is_open = false
			peer.disconnect_from_host()
			connection_closed.emit(code, reason)

		OPCODE_PING:
			# Respond with pong
			_send_frame(OPCODE_PONG, payload)

		OPCODE_PONG:
			_waiting_pong = false  # Keep-alive response received.

		_:
			close(1002, "Unknown opcode")


func _emit_message(opcode: int, payload: PackedByteArray) -> void:
	if opcode == OPCODE_TEXT:
		message_received.emit(payload.get_string_from_utf8(), false)
	else:
		message_received.emit(payload, true)


func _send_frame(opcode: int, payload: PackedByteArray) -> void:
	if not is_open and opcode != OPCODE_CLOSE:
		return

	var header := PackedByteArray()
	header.append(0x80 | opcode)  # FIN + opcode

	var len := payload.size()
	if len < 126:
		header.append(len)
	elif len < 65536:
		header.append(126)
		header.append((len >> 8) & 0xFF)
		header.append(len & 0xFF)
	else:
		header.append(127)
		for i in range(7, -1, -1):
			header.append((len >> (i * 8)) & 0xFF)

	var frame := header
	frame.append_array(payload)
	peer.put_data(frame)
