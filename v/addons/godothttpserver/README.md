# GodotHTTPServer

A production-grade HTTP/HTTPS server that runs natively inside Godot. Built for game servers, web dashboards, REST APIs, and file hosting.

## Features

- **Full HTTP/1.1 support** — GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
- **Advanced Routing** — route groups, path parameters, and regex constraints (e.g., `/users/{id:[0-9]+}`)
- **Middleware Chain** — apply global middleware or scope it specifically to individual routes and groups
- **Built-in Middleware** — CORS, Logging, Rate Limiting, and GZIP Compression
- **DTO Validation** — type-safe request body validation with nested DTOs, arrays, and type coercion
- **Multipart / Form-Data** — native parsing for file uploads
- **WebSocket support** — full WebSocket protocol (RFC 6455) with automatic handshake handling
- **Advanced Static Serving** — MIME type detection, ETag caching, and `Accept-Ranges` for video streaming
- **Chunked Transfer Encoding** — streaming support for both inbound requests and outbound responses (SSE)
- **HTTPS/TLS** — native TLS support via `TLSOptions`
- **Connection Management** — keep-alive pipelines, idle timeouts, handshake timeouts, and max request size limits
- **Graceful Shutdown** — closes all connections cleanly

## Installation

1. Copy the `addons/godothttpserver` directory into your project's `addons/` folder.
2. Enable the plugin in **Project Settings → Plugins**.
3. Add an `HTTPServer` node to your scene.

## Quick Start

```gdscript
# In your scene script
@onready var server: HTTPServer = $HTTPServer

func _ready() -> void:
	# Add global middleware
	server.use(LoggingMiddleware.new())
	server.use(CompressionMiddleware.new())
	server.use(CORSMiddleware.new(["*"]))

	# Register standard routes
	server.router.handle_get("/", _handle_root)
	
	# Register routes with regex constraints (id must be numeric)
	server.router.handle_get("/users/{id:[0-9]+}", _handle_get_user)
	
	# Register routes with automatic DTO validation
	server.router.handle_post("/users", _handle_create_user, CreateUserDto)

	# Create route groups with scoped middleware
	server.router.group("/api/v1", func(r: HTTPRouter):
		r.handle_get("/secure", _handle_secure_data, null, [AuthMiddleware.new()])
	)

	# Start the server
	var err := server.start(8080)
	if err != OK:
		push_error("Failed to start server: %s" % error_string(err))

func _handle_root(_path_params: Dictionary, _query: Dictionary, _headers: Dictionary, _body: Variant) -> HTTPResponse:
	return HTTPResponse.ok("Hello, world!")

func _handle_get_user(path_params: Dictionary, _query: Dictionary, _headers: Dictionary, _body: Variant) -> HTTPResponse:
	var user_id: String = path_params["id"]
	return HTTPResponse.ok("User: %s" % user_id)

func _handle_create_user(_path_params: Dictionary, _query: Dictionary, _headers: Dictionary, dto: Variant) -> HTTPResponse:
	var user_dto: CreateUserDto = dto
	return HTTPResponse.created("Created user: %s" % user_dto.get_value("name"))

```

## DTO Validation

```gdscript
class_name CreateUserDto
extends HTTPDto

func _init() -> void:
	register_field("name", TYPE_STRING)
	register_field("age", TYPE_INT)
	register_optional_field("email", TYPE_STRING)
	register_validated_field("password", TYPE_STRING, func(p): return p.length() >= 8)
	register_nested_dto("address", AddressDto)
	register_array_field("tags", TYPE_STRING)

```

## Middleware

```gdscript
class_name AuthMiddleware
extends HTTPMiddleware

func process_request(request: HTTPMessage) -> Variant:
	var token := request.header("authorization")
	if token.is_empty():
		return HTTPResponse.unauthorized("Missing auth token")
	# Validate token...
	return null  # Continue

func process_response(_request: HTTPMessage, response: HTTPResponse) -> HTTPResponse:
	response.set_header("X-Powered-By", "GodotHTTPServer")
	return response

```

## WebSockets

```gdscript
func _ready() -> void:
	server.websocket_connected.connect(_on_ws_connected)

func _on_ws_connected(ws: WebSocketConnection) -> void:
	ws.message_received.connect(func(data, is_binary):
		if not is_binary:
			ws.send_text("Echo: %s" % data)
	)

```

## Static Files

Serve files from a directory using a middleware (supports ETags and Video Streaming!):

```gdscript
class_name StaticFileMiddleware
extends HTTPMiddleware

var static_files := StaticFileServer.new("res://web")

func process_request(request: HTTPMessage) -> Variant:
	if request.method == "GET" and request.clean_path.begins_with("/static/"):
		return static_files.handle(request)
	return null

```

Then register it:

```gdscript
server.use(StaticFileMiddleware.new())

```

## HTTPS

```gdscript
func _ready() -> void:
	var err := server.setup_tls("res://cert.pem", "res://key.pem")
	if err == OK:
		server.start(443)

```

## Configuration

| Property | Default | Description |
| --- | --- | --- |
| `max_connections` | 100 | Maximum concurrent connections |
| `max_request_size` | 10 MB | Maximum request body size |
| `idle_timeout` | 30s | Close idle connections |
| `handshake_timeout` | 10s | TLS handshake timeout |
| `max_keep_alive_requests` | 100 | Max requests per keep-alive connection |
| `poll_interval` | 0.05s | Connection polling frequency |

## License

MIT