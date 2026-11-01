class_name HTTPResponse
extends RefCounted

## A fully-featured HTTP response object.
## Supports custom headers, configurable content types, and all standard status codes.

var code: int = 200
var status_text: String = "OK"
var headers: Dictionary = {}
var body: PackedByteArray = PackedByteArray()
var content_type: String = "application/json"
var _connection_close: bool = false

var is_chunked: bool = false

## Set-Cookie header lines managed by `set_cookie` / `delete_cookie`.
var _cookie_headers: Array[String] = []

## Optional callback invoked after headers are sent to stream the body (chunked).
var _body_stream: Callable = Callable()

## When true, the handler already sent (or owns) the response over the connection,
## so the server skips its automatic send. Used by streaming helpers such as SSE.
var _handled_externally: bool = false

func _init(p_code: int = 200, p_status: String = "OK", p_body: String = "") -> void:
	code = p_code
	status_text = p_status
	if not p_body.is_empty():
		body = p_body.to_utf8_buffer()


## Sets a custom header on the response.
func set_header(name: String, value: String) -> HTTPResponse:
	headers[name] = value
	return self


## Adds a Set-Cookie header. Encode sensitive values before calling.
## Options supported: path, max_age (seconds), domain, secure, http_only, same_site.
func set_cookie(name: String, value: String, path: String = "/", max_age: int = -1, domain: String = "", secure: bool = false, http_only: bool = false, same_site: String = "") -> HTTPResponse:
	_cookie_headers.append(_build_cookie(name, value.uri_encode(), path, max_age, domain, secure, http_only, same_site))
	return self


## Adds a Set-Cookie header that expires the named cookie immediately.
func delete_cookie(name: String, path: String = "/", domain: String = "") -> HTTPResponse:
	_cookie_headers.append(_build_cookie(name, "", path, 0, domain, false, true, ""))
	return self


## Sets the Content-Type header. Defaults to application/json.
func set_content_type(type: String) -> HTTPResponse:
	content_type = type
	return self


## Sets the response body from a string.
func set_body(text: String) -> HTTPResponse:
	body = text.to_utf8_buffer()
	return self


## Sets the response body from raw bytes.
func set_body_bytes(bytes: PackedByteArray) -> HTTPResponse:
	body = bytes
	return self


## Sets a callback used to stream the body over the connection (chunked encoding).
func set_body_stream(callback: Callable) -> HTTPResponse:
	_body_stream = callback
	return self


func get_body_stream() -> Callable:
	return _body_stream


## Marks the response as already streamed externally (e.g. SSE), so the server
## does not send it again automatically.
func mark_handled() -> HTTPResponse:
	_handled_externally = true
	return self


func is_handled_externally() -> bool:
	return _handled_externally


## Serializes a Variant to JSON and sets it as the body.
func set_json(data: Variant) -> HTTPResponse:
	body = JSON.stringify(data).to_utf8_buffer()
	content_type = "application/json"
	return self


## Marks this response to close the connection after sending.
func close_connection() -> HTTPResponse:
	_connection_close = true
	return self


func should_close_connection() -> bool:
	return _connection_close


## Builds the raw HTTP response bytes to send over the wire.
func to_bytes() -> PackedByteArray:
	var head := "HTTP/1.1 %d %s\r\n" % [code, status_text]
	if not is_chunked:
		head += "Content-Length: %d\r\n" % body.size()
	else:
		head += "Transfer-Encoding: chunked\r\n"
	
	head += "Content-Type: %s\r\n" % content_type

	# 1xx responses carry no entity headers or message metadata.
	if code >= 200:
		if not _has_header_ci("Server"):
			head += "Server: GodotHTTPServer\r\n"
		if not _has_header_ci("Date"):
			head += "Date: %s\r\n" % HTTPDate.now()

	for cookie_line in _cookie_headers:
		head += "Set-Cookie: %s\r\n" % cookie_line

	for key in headers:
		head += "%s: %s\r\n" % [key, headers[key]]
	if _connection_close:
		head += "Connection: close\r\n"
	head += "\r\n"
	
	var result := head.to_utf8_buffer()
	if not is_chunked:
		result.append_array(body)
	return result


## Returns true when a header with the given name (case-insensitive) already exists.
func _has_header_ci(name: String) -> bool:
	for key in headers:
		if String(key).to_lower() == name.to_lower():
			return true
	return false


## Builds a single Set-Cookie header value from the given cookie attributes.
func _build_cookie(name: String, value: String, path: String, max_age: int, domain: String, secure: bool, http_only: bool, same_site: String) -> String:
	var parts: Array[String] = ["%s=%s" % [name, value]]
	if path != "":
		parts.append("Path=%s" % path)
	if domain != "":
		parts.append("Domain=%s" % domain)
	if max_age >= 0:
		parts.append("Max-Age=%d" % max_age)
	if secure:
		parts.append("Secure")
	if http_only:
		parts.append("HttpOnly")
	if same_site != "":
		parts.append("SameSite=%s" % same_site)
	return "; ".join(parts)


# ==========================================
# 1xx INFORMATIONAL
# ==========================================

static func continue_100() -> HTTPResponse:
	return HTTPResponse.new(100, "Continue")


static func switching_protocols() -> HTTPResponse:
	return HTTPResponse.new(101, "Switching Protocols")


# ==========================================
# 2xx SUCCESS
# ==========================================

static func ok(body: String = "") -> HTTPResponse:
	return HTTPResponse.new(200, "OK", body)


static func created(body: String = "") -> HTTPResponse:
	return HTTPResponse.new(201, "Created", body)


static func accepted(body: String = "") -> HTTPResponse:
	return HTTPResponse.new(202, "Accepted", body)


static func no_content() -> HTTPResponse:
	return HTTPResponse.new(204, "No Content")


static func reset_content() -> HTTPResponse:
	return HTTPResponse.new(205, "Reset Content")


static func partial_content(body: String = "") -> HTTPResponse:
	return HTTPResponse.new(206, "Partial Content", body)


# ==========================================
# 3xx REDIRECTION
# ==========================================

static func multiple_choices() -> HTTPResponse:
	return HTTPResponse.new(300, "Multiple Choices")


static func moved_permanently(location: String) -> HTTPResponse:
	var resp := HTTPResponse.new(301, "Moved Permanently")
	resp.set_header("Location", location)
	return resp


static func found(location: String) -> HTTPResponse:
	var resp := HTTPResponse.new(302, "Found")
	resp.set_header("Location", location)
	return resp


static func see_other(location: String) -> HTTPResponse:
	var resp := HTTPResponse.new(303, "See Other")
	resp.set_header("Location", location)
	return resp


static func not_modified() -> HTTPResponse:
	return HTTPResponse.new(304, "Not Modified")


static func temporary_redirect(location: String) -> HTTPResponse:
	var resp := HTTPResponse.new(307, "Temporary Redirect")
	resp.set_header("Location", location)
	return resp


static func permanent_redirect(location: String) -> HTTPResponse:
	var resp := HTTPResponse.new(308, "Permanent Redirect")
	resp.set_header("Location", location)
	return resp


# ==========================================
# 4xx CLIENT ERROR
# ==========================================

static func bad_request(error_message: String = "Bad Request") -> HTTPResponse:
	return HTTPResponse.new(400, "Bad Request").set_json({"error": error_message})


static func unauthorized(error_message: String = "Unauthorized") -> HTTPResponse:
	return HTTPResponse.new(401, "Unauthorized").set_json({"error": error_message})


static func payment_required(error_message: String = "Payment Required") -> HTTPResponse:
	return HTTPResponse.new(402, "Payment Required").set_json({"error": error_message})


static func forbidden(error_message: String = "Forbidden") -> HTTPResponse:
	return HTTPResponse.new(403, "Forbidden").set_json({"error": error_message})


static func not_found(error_message: String = "Not Found") -> HTTPResponse:
	return HTTPResponse.new(404, "Not Found").set_json({"error": error_message})


static func method_not_allowed(error_message: String = "Method Not Allowed") -> HTTPResponse:
	return HTTPResponse.new(405, "Method Not Allowed").set_json({"error": error_message})


static func not_acceptable(error_message: String = "Not Acceptable") -> HTTPResponse:
	return HTTPResponse.new(406, "Not Acceptable").set_json({"error": error_message})


static func request_timeout(error_message: String = "Request Timeout") -> HTTPResponse:
	return HTTPResponse.new(408, "Request Timeout").set_json({"error": error_message})


static func conflict(error_message: String = "Conflict") -> HTTPResponse:
	return HTTPResponse.new(409, "Conflict").set_json({"error": error_message})


static func gone(error_message: String = "Gone") -> HTTPResponse:
	return HTTPResponse.new(410, "Gone").set_json({"error": error_message})


static func length_required(error_message: String = "Length Required") -> HTTPResponse:
	return HTTPResponse.new(411, "Length Required").set_json({"error": error_message})


static func payload_too_large(error_message: String = "Payload Too Large") -> HTTPResponse:
	return HTTPResponse.new(413, "Payload Too Large").set_json({"error": error_message})


static func uri_too_long(error_message: String = "URI Too Long") -> HTTPResponse:
	return HTTPResponse.new(414, "URI Too Long").set_json({"error": error_message})


static func unsupported_media_type(error_message: String = "Unsupported Media Type") -> HTTPResponse:
	return HTTPResponse.new(415, "Unsupported Media Type").set_json({"error": error_message})


static func range_not_satisfiable(error_message: String = "Range Not Satisfiable") -> HTTPResponse:
	return HTTPResponse.new(416, "Range Not Satisfiable").set_json({"error": error_message})


static func unprocessable_entity(error_message: String = "Unprocessable Entity") -> HTTPResponse:
	return HTTPResponse.new(422, "Unprocessable Entity").set_json({"error": error_message})


static func too_many_requests(error_message: String = "Too Many Requests") -> HTTPResponse:
	return HTTPResponse.new(429, "Too Many Requests").set_json({"error": error_message})


# ==========================================
# 5xx SERVER ERROR
# ==========================================

static func internal_server_error(error_message: String = "Internal Server Error") -> HTTPResponse:
	return HTTPResponse.new(500, "Internal Server Error").set_json({"error": error_message})


static func not_implemented(error_message: String = "Not Implemented") -> HTTPResponse:
	return HTTPResponse.new(501, "Not Implemented").set_json({"error": error_message})


static func bad_gateway(error_message: String = "Bad Gateway") -> HTTPResponse:
	return HTTPResponse.new(502, "Bad Gateway").set_json({"error": error_message})


static func service_unavailable(error_message: String = "Service Unavailable") -> HTTPResponse:
	return HTTPResponse.new(503, "Service Unavailable").set_json({"error": error_message})


static func gateway_timeout(error_message: String = "Gateway Timeout") -> HTTPResponse:
	return HTTPResponse.new(504, "Gateway Timeout").set_json({"error": error_message})


static func http_version_not_supported(error_message: String = "HTTP Version Not Supported") -> HTTPResponse:
	return HTTPResponse.new(505, "HTTP Version Not Supported").set_json({"error": error_message})
