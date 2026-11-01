class_name HTTPConnection
extends RefCounted

## Manages the state of a single client connection.
## Handles raw byte buffering, request parsing, keep-alive, and timeouts.

signal request_received(request: HTTPMessage)
signal connection_closed

var peer: StreamPeer = null
var is_tls: bool = false
var buffer: PackedByteArray = PackedByteArray()
var last_activity: float = 0.0
var request_count: int = 0
var max_keep_alive_requests: int = 100
var max_request_size: int = 10 * 1024 * 1024  # 10 MB default
var idle_timeout: float = 30.0
var handshake_timeout: float = 10.0
var is_handshaking: bool = false
var is_upgraded: bool = false
var _closed: bool = false

## Header byte offset of the request for which a 100 Continue has been sent.
## Prevents sending the interim response more than once for the same request.
var _sent_continue_offset: int = -1


func _init(p_peer: StreamPeer, p_is_tls: bool = false) -> void:
	peer = p_peer
	is_tls = p_is_tls
	is_handshaking = p_is_tls
	last_activity = Time.get_ticks_msec() / 1000.0


func poll() -> void:
	if _closed or peer == null:
		return

	if peer.has_method("poll"):
		peer.poll()

	var now := Time.get_ticks_msec() / 1000.0

	# TLS connection state check
	if is_tls:
		var tls_peer := peer as StreamPeerTLS
		if tls_peer == null:
			close()
			return

		var status := tls_peer.get_status()

		if is_handshaking:
			if status == StreamPeerTLS.STATUS_CONNECTED:
				is_handshaking = false
				last_activity = now
			elif status == StreamPeerTLS.STATUS_HANDSHAKING:
				if now - last_activity > handshake_timeout:
					close()
				return
			else:
				close()
				return

		if status != StreamPeerTLS.STATUS_CONNECTED:
			close()
			return

	# Non-TLS connection state check (StreamPeerTCP)
	else:
		var status := StreamPeerTCP.STATUS_CONNECTED
		if peer is StreamPeerTCP:
			status = (peer as StreamPeerTCP).get_status()
		elif peer.has_method("get_status"):
			status = peer.get_status()

		if status != 2:
			close()
			return

	# Read available data into the buffer
	var available := peer.get_available_bytes()
	if available > 0:
		var data := peer.get_data(available)
		if data[0] == OK:
			buffer.append_array(data[1])
			last_activity = now
		else:
			close()
			return

	# Check idle timeout
	if now - last_activity > idle_timeout:
		if buffer.size() > 0:
			_send_408()  # Client stalled while sending the request headers/body.
		else:
			close()
		return

	# Check request size limit
	if buffer.size() > max_request_size:
		_send_413()
		return

	# Try to parse complete requests from the buffer
	_parse_requests()

func _parse_requests() -> void:
	while not _closed:
		var header_end := _find_header_end()
		if header_end == -1:
			return  # Need more data

		var header_bytes := buffer.slice(0, header_end)
		var header_text := header_bytes.get_string_from_utf8()
		var lines := header_text.split("\r\n")

		if lines.is_empty() or lines[0].is_empty():
			# Empty header section - malformed, close
			close()
			return

		var request_line := lines[0].split(" ")
		if request_line.size() < 3:
			# Malformed request line
			close()
			return

		var method := request_line[0].to_upper()
		var path := request_line[1]
		var http_version := request_line[2]

		# Parse headers
		var headers := {}
		for i in range(1, lines.size()):
			var line := lines[i]
			if line.is_empty():
				continue
			var header_parts := line.split(":", true, 1)
			if header_parts.size() == 2:
				headers[header_parts[0].strip_edges().to_lower()] = header_parts[1].strip_edges()

		# Determine body length
		var content_length := 0
		if headers.has("content-length"):
			content_length = int(headers["content-length"])
			if content_length < 0:
				close()
				return

		# Check for chunked transfer encoding
		var transfer_encoding : String = headers.get("transfer-encoding", "").to_lower()
		var body_start := header_end + 4  # Skip \r\n\r\n
		var body := PackedByteArray()
		var consumed := 0
		var expect_continue = headers.get("expect", "").to_lower().contains("100-continue")

		if transfer_encoding.contains("chunked"):
			var chunk_result := _decode_chunked(body_start)
			if chunk_result.is_empty():
				# More chunk data is needed; send 100 Continue if expected.
				_try_send_continue(header_end, expect_continue)
				return
			body = chunk_result[0]
			consumed = chunk_result[1]
		else:
			if content_length > max_request_size:
				_send_413()
				return
			var total_needed := body_start + content_length
			if buffer.size() < total_needed:
				# Body not fully received yet; send 100 Continue if expected.
				_try_send_continue(header_end, expect_continue)
				return
			body = buffer.slice(body_start, body_start + content_length)
			consumed = total_needed

		# Remove this request from the buffer
		buffer = buffer.slice(consumed)
		_sent_continue_offset = -1

		# Build the request message
		var request := HTTPMessage.new()
		request.method = method
		request.path = path
		request.http_version = http_version
		request.headers = headers
		request.body = body
		request.parse_cookies()

		# Parse query string
		var path_parts := path.split("?", true, 1)
		request.clean_path = path_parts[0]
		request.query_string = path_parts[1] if path_parts.size() > 1 else ""
		request.query_params = _parse_query_string(request.query_string)

		# Detect WebSocket upgrade
		var upgrade : String = headers.get("upgrade", "").to_lower()
		var connection : String = headers.get("connection", "").to_lower()
		request.is_websocket_upgrade = upgrade == "websocket" and connection.contains("upgrade")

		request_count += 1
		last_activity = Time.get_ticks_msec() / 1000.0

		request_received.emit(request)

		# Stop parsing if the connection was closed or upgraded during the signal handler
		if _closed or is_upgraded:
			return

		# Check if we should close after this request
		var connection_header : String = headers.get("connection", "").to_lower()
		if connection_header.contains("close") or request_count >= max_keep_alive_requests:
			close()
			return


## Decodes a chunked transfer-encoded body starting at `start_offset`.
## Returns [body_bytes, total_consumed] or an empty array if more data is needed.
func _decode_chunked(start_offset: int) -> Array:
	var pos := start_offset
	var result := PackedByteArray()

	while true:
		# Find the end of the chunk-size line
		var line_end := _find_crlf(pos)
		if line_end == -1:
			return []  # Need more data

		var size_line := buffer.slice(pos, line_end).get_string_from_utf8()
		# Chunk size is hex, possibly with extensions after ';'
		var size_str := size_line.split(";")[0].strip_edges()
		var chunk_size := size_str.hex_to_int()
		if chunk_size < 0:
			close()
			return []

		pos = line_end + 2  # Skip \r\n

		if chunk_size == 0:
			# Last chunk - consume trailing \r\n
			if buffer.size() < pos + 2:
				return []
			pos += 2
			return [result, pos - start_offset]

		# Check if we have the full chunk data + trailing CRLF
		if buffer.size() < pos + chunk_size + 2:
			return []  # Need more data

		result.append_array(buffer.slice(pos, pos + chunk_size))
		pos += chunk_size + 2  # Skip chunk data and trailing \r\n

		# Safety check
		if result.size() > max_request_size:
			_send_413()
			return []
	return []

func _find_crlf(start: int) -> int:
	for i in range(start, buffer.size() - 1):
		if buffer[i] == 13 and buffer[i + 1] == 10:
			return i
	return -1


func _find_header_end() -> int:
	# Search for \r\n\r\n in the buffer
	for i in range(buffer.size() - 3):
		if buffer[i] == 13 and buffer[i + 1] == 10 and buffer[i + 2] == 13 and buffer[i + 3] == 10:
			return i
	return -1


func _parse_query_string(query_string: String) -> Dictionary:
	var result := {}
	if query_string.is_empty():
		return result
	var pairs := query_string.split("&")
	for pair in pairs:
		var kv := pair.split("=", true, 1)
		var key := kv[0].replace("+", " ").uri_decode()
		var value := kv[1].replace("+", " ").uri_decode() if kv.size() > 1 else ""
		if result.has(key):
			# Multiple values for the same key become an array
			if result[key] is Array:
				result[key].append(value)
			else:
				result[key] = [result[key], value]
		else:
			result[key] = value
	return result


## Sends the interim 100 Continue response when the client asks for it with
## Expect: 100-continue. Sends it at most once per request.
func _try_send_continue(header_offset: int, expect_continue: bool) -> void:
	if not expect_continue or _closed or _sent_continue_offset == header_offset:
		return
	_sent_continue_offset = header_offset
	peer.put_data("HTTP/1.1 100 Continue\r\n\r\n".to_utf8_buffer())
	last_activity = Time.get_ticks_msec() / 1000.0


## Sends a 413 Payload Too Large response, then closes the connection.
func _send_413() -> void:
	send_response(HTTPResponse.payload_too_large("Request body too large"))
	close()


## Sends a 408 Request Timeout response, then closes the connection.
func _send_408() -> void:
	send_response(HTTPResponse.request_timeout("Request timed out"))
	close()


func send_response(response: HTTPResponse) -> void:
	if _closed:
		return
	var bytes := response.to_bytes()
	peer.put_data(bytes)
	last_activity = Time.get_ticks_msec() / 1000.0


## Streams a raw byte chunk to the client using Transfer-Encoding: chunked.
func send_chunk(chunk: PackedByteArray) -> void:
	if _closed or chunk.is_empty(): return
	var hex_len := String.num_int64(chunk.size(), 16).to_utf8_buffer()
	peer.put_data(hex_len)
	peer.put_data("\r\n".to_utf8_buffer())
	peer.put_data(chunk)
	peer.put_data("\r\n".to_utf8_buffer())
	last_activity = Time.get_ticks_msec() / 1000.0

## Finishes a chunked stream connection.
func finish_chunked_response() -> void:
	if _closed: return
	peer.put_data("0\r\n\r\n".to_utf8_buffer())
	last_activity = Time.get_ticks_msec() / 1000.0


func close() -> void:
	if _closed:
		return
	_closed = true
	if peer != null:
		if peer is StreamPeerTLS:
			peer.disconnect_from_stream()
		elif peer is StreamPeerTCP:
			peer.disconnect_from_host()
	connection_closed.emit()


func is_closed() -> bool:
	return _closed
