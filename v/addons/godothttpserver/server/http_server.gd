class_name HTTPServer
extends Node

## A production-grade HTTP/HTTPS server for Godot.
## Supports keep-alive connections, TLS, middleware, routing, and WebSocket upgrades.

signal request_handled(request: HTTPMessage, response: HTTPResponse)
signal client_connected(ip: String)
signal client_disconnected(ip: String)
signal server_started(port: int)
signal server_stopped
signal websocket_connected(connection: WebSocketConnection)
signal websocket_disconnected(connection: WebSocketConnection, code: int, reason: String)

var router := HTTPRouter.new()
var websocket_hub := WebSocketHub.new()

## Configuration
var max_connections: int = 100
var max_request_size: int = 10 * 1024 * 1024  # 10 MB
var idle_timeout: float = 30.0
var handshake_timeout: float = 10.0
var max_keep_alive_requests: int = 100
var poll_interval: float = 0.05  # 20 Hz polling
## IP address to bind. Defaults to loopback for security; use "0.0.0.0" to listen on all interfaces.
var bind_address: String = "127.0.0.1"
## Seconds to wait for in-flight requests during a graceful shutdown() before forcing close.
var drain_timeout: float = 5.0

var _server := TCPServer.new()
var _connections: Array[HTTPConnection] = []
var _websocket_connections: Array[WebSocketConnection] = []
var _middlewares: Array[HTTPMiddleware] = []
var _tls_options: TLSOptions = null
var _use_tls := false
var _running := false
var _poll_timer: Timer = null
var _drain_timer: Timer = null
var _stopping := false
var _draining := false


func _ready() -> void:
	_poll_timer = Timer.new()
	_poll_timer.wait_time = poll_interval
	_poll_timer.autostart = false
	_poll_timer.timeout.connect(_poll_connections)
	add_child(_poll_timer)


func _exit_tree() -> void:
	stop()


# ==========================================
# PUBLIC API
# ==========================================

## Registers a middleware in the request/response chain.
func use(middleware: HTTPMiddleware) -> void:
	_middlewares.append(middleware)


## Configures TLS. Call BEFORE start() to enable HTTPS.
func setup_tls(cert_path: String, key_path: String) -> Error:
	var cert := X509Certificate.new()
	var cert_err := cert.load(cert_path)
	if cert_err != OK:
		push_error("HTTPServer: Failed to load TLS certificate from: %s" % cert_path)
		return cert_err

	var key := CryptoKey.new()
	var key_err := key.load(key_path)
	if key_err != OK:
		push_error("HTTPServer: Failed to load TLS key from: %s" % key_path)
		return key_err

	_tls_options = TLSOptions.server(key, cert)
	_use_tls = true
	return OK


## Starts the server on the given port. Returns OK on success.
func start(port: int = 8080) -> Error:
	if _running:
		push_warning("HTTPServer: Server is already running.")
		return ERR_ALREADY_IN_USE

	var err := _server.listen(port, bind_address)
	if err != OK:
		push_error("HTTPServer: Failed to listen on %s:%d: %s" % [bind_address, port, error_string(err)])
		return err

	_running = true
	_stopping = false
	_poll_timer.start()

	var protocol := "HTTPS" if _use_tls else "HTTP"
	print("HTTPServer: %s server started on port %d" % [protocol, port])
	server_started.emit(port)
	return OK


## Stops the server immediately, closing all connections.
func stop() -> void:
	if not _running:
		return

	_stopping = true
	_draining = false
	_stop_poll_and_drain_timers()
	_server.stop()
	_close_all_connections(1001, "Server shutting down")
	_finalize_stop()


## Stops accepting new connections and waits up to `drain_timeout` seconds for
## in-flight requests to finish before closing the remaining connections.
func shutdown(p_drain_timeout: float = -1.0) -> void:
	if not _running:
		return

	if p_drain_timeout >= 0.0:
		drain_timeout = p_drain_timeout

	_draining = true
	_server.stop()

	if _drain_timer != null:
		_drain_timer.queue_free()
	_drain_timer = Timer.new()
	_drain_timer.one_shot = true
	_drain_timer.wait_time = maxf(drain_timeout, 0.0)
	_drain_timer.timeout.connect(_force_finish_shutdown)
	add_child(_drain_timer)
	_drain_timer.start()

	# Keep polling so in-flight requests can complete.
	_poll_timer.start()


func is_running() -> bool:
	return _running


func get_connection_count() -> int:
	return _connections.size() + _websocket_connections.size()


func get_websocket_connections() -> Array[WebSocketConnection]:
	return _websocket_connections


# ==========================================
# SHUTDOWN HELPERS
# ==========================================

## Stops and frees both the poll and drain timers.
func _stop_poll_and_drain_timers() -> void:
	_poll_timer.stop()
	if _drain_timer != null:
		_drain_timer.stop()
		_drain_timer.queue_free()
		_drain_timer = null


## Closes every tracked HTTP and WebSocket connection.
func _close_all_connections(ws_code: int, ws_reason: String) -> void:
	var conns := _connections.duplicate()
	for conn in conns:
		conn.close()
	_connections.clear()

	var ws_conns := _websocket_connections.duplicate()
	for ws in ws_conns:
		ws.close(ws_code, ws_reason)
	_websocket_connections.clear()


## Completes a graceful drain once no connections remain.
func _finish_drained_shutdown() -> void:
	_draining = false
	_stopping = true
	_stop_poll_and_drain_timers()
	_close_all_connections(1001, "Server shutting down")
	_finalize_stop()


## Forced by the drain timer: closes remaining connections and finalizes.
func _force_finish_shutdown() -> void:
	if _draining:
		_finish_drained_shutdown()


## Marks the server as stopped and emits the stop signal.
func _finalize_stop() -> void:
	_running = false
	_stopping = false
	print("HTTPServer: Server stopped")
	server_stopped.emit()


# ==========================================
# INTERNAL
# ==========================================

func _poll_connections() -> void:
	if not _running:
		return

	# Accept new connections (disabled while draining or stopping).
	if not _draining and not _stopping and _server.is_connection_available():
		var tcp_peer: StreamPeerTCP = _server.take_connection()
		if _connections.size() + _websocket_connections.size() >= max_connections:
			_reject_with_503(tcp_peer)
			return

		var ip := tcp_peer.get_connected_host()
		var peer: StreamPeer = tcp_peer

		if _use_tls:
			var tls_peer := StreamPeerTLS.new()
			if tls_peer.accept_stream(tcp_peer, _tls_options) == OK:
				peer = tls_peer
			else:
				tcp_peer.disconnect_from_host()
				return

		# Pass 'peer' (which holds StreamPeerTLS when TLS is enabled)
		var conn := HTTPConnection.new(peer, _use_tls)
		conn.max_request_size = max_request_size
		conn.idle_timeout = idle_timeout
		conn.handshake_timeout = handshake_timeout
		conn.max_keep_alive_requests = max_keep_alive_requests
		
		conn.request_received.connect(_on_request_received.bind(conn))
		_connections.append(conn)

		client_connected.emit(ip)

	# Poll existing HTTP connections
	for i in range(_connections.size() - 1, -1, -1):
		var conn := _connections[i]
		conn.poll()
		if conn.is_closed() or conn.is_upgraded:
			_connections.remove_at(i)
			if not conn.is_upgraded:
				client_disconnected.emit(_get_peer_ip(conn.peer))

	# Poll WebSocket connections
	for i in range(_websocket_connections.size() - 1, -1, -1):
		var ws := _websocket_connections[i]
		ws.poll()
		if ws.is_closed():
			_websocket_connections.remove_at(i)

	# Finish a graceful shutdown once every connection has drained.
	if _draining and _connections.is_empty() and _websocket_connections.is_empty():
		_finish_drained_shutdown()


## Sends a 503 Service Unavailable to a peer that cannot be accepted, then closes it.
func _reject_with_503(tcp_peer: StreamPeerTCP) -> void:
	var body := '{"error":"Server at capacity"}'
	var head := "HTTP/1.1 503 Service Unavailable\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [body.to_utf8_buffer().size(), body]
	tcp_peer.put_data(head.to_utf8_buffer())
	tcp_peer.disconnect_from_host()


func _on_request_received(request: HTTPMessage, conn: HTTPConnection) -> void:
	# Set client IP
	request.client_ip = _get_peer_ip(conn.peer)
	request.connection = conn

	# Check for WebSocket upgrade
	if request.is_websocket_upgrade:
		_handle_websocket_upgrade(request, conn)
		return

	# Run request middleware chain
	for mw in _middlewares:
		var mw_result := mw.process_request(request)
		if mw_result is HTTPResponse:
			_send_response(conn, request, mw_result)
			return

	# Route the request
	var response := router.route_request(request)

	# Run response middleware chain (in reverse order)
	for i in range(_middlewares.size() - 1, -1, -1):
		response = _middlewares[i].process_response(request, response)

	_send_response(conn, request, response)


func _handle_websocket_upgrade(request: HTTPMessage, conn: HTTPConnection) -> void:
	# Create a WebSocket connection on the same peer
	var ws := WebSocketConnection.new(conn.peer)
	ws.idle_timeout = idle_timeout

	if not ws.perform_handshake(request):
		# Failed handshake - send 400 and close
		var response := HTTPResponse.bad_request("Invalid WebSocket handshake")
		conn.send_response(response)
		conn.close()
		return

	# Mark the HTTP connection as upgraded so the poll loop removes it.
	conn.is_upgraded = true

	# Track the WebSocket connection. The poll loop handles removal.
	# The connection_closed signal emits websocket_disconnected with the
	# actual close code/reason, without modifying the array during iteration.
	ws.connection_closed.connect(_on_websocket_closed.bind(ws))
	_websocket_connections.append(ws)

	websocket_connected.emit(ws)


func _on_websocket_closed(code: int, reason: String, ws: WebSocketConnection) -> void:
	# Remove the connection from its rooms.
	websocket_hub.leave_all(ws)
	# Emit the disconnect signal with the real close code/reason.
	# We don't erase() from _websocket_connections here to avoid
	# corrupting the poll loop iteration. The poll loop removes it.
	websocket_disconnected.emit(ws, code, reason)


func _send_response(conn: HTTPConnection, request: HTTPMessage, response: HTTPResponse) -> void:
	# If the connection should close (e.g., Connection: close header), mark it
	if request.header("connection").to_lower().contains("close"):
		response.close_connection()

	# Streaming helpers (SSE, static file streaming) may send on their own.
	if not response.is_handled_externally():
		conn.send_response(response)

		# Stream the body (chunked) when a stream callback is attached.
		var stream_callback := response.get_body_stream()
		if stream_callback.is_valid() and request.method != "HEAD":
			stream_callback.call(conn)

	request_handled.emit(request, response)


func _get_peer_ip(peer: StreamPeer) -> String:
	if peer is StreamPeerTCP:
		return (peer as StreamPeerTCP).get_connected_host()
	return ""
